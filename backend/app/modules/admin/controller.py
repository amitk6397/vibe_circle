from datetime import UTC, datetime

from sqlalchemy import func, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.admin.dtos import (
    CoinPackageCreate,
    CoinPackageUpdate,
    CommunityStatusUpdate,
    CreatorApplicationReview,
    PlatformSettingsUpdate,
    ReportReview,
    SubscriptionPlanCreate,
    SubscriptionPlanUpdate,
    SupportArticleCreate,
    SupportArticleUpdate,
    UserStatusUpdate,
    WithdrawalReview,
    VirtualGiftCreate,
    VirtualGiftUpdate,
    SpecialOfferCreate,
    SpecialOfferUpdate,
)
from app.modules.app_content.models import SupportArticle
from app.modules.commerce.models import CoinPackage, SubscriptionPlan, UserSubscription, UserWallet, WalletTransaction
from app.modules.communities.models import Community
from app.modules.creators.models import CreatorApplication, CreatorProfile, WithdrawalRequest
from app.modules.engagement.models import VirtualGift
from app.modules.moderation.models import AuditLog, Report
from app.modules.moderation.service import audit, require_admin
from app.modules.notifications.service import create_notification
from app.modules.creators import service as creator_service
from app.modules.users.models import User
from app.core.config import settings


# ── Helpers ───────────────────────────────────────────────────────────────────

def _require(db: DbSession, model, pk: str, label: str):
    item = db.get(model, pk)
    if not item:
        raise AppError(404, f"{label}_not_found", f"{label.replace('_', ' ').title()} not found.")
    return item


# ── Dashboard ─────────────────────────────────────────────────────────────────

def dashboard(db: DbSession, user: CurrentUser):
    require_admin(user)

    today = datetime.now(UTC).date()
    total_users = db.scalar(select(func.count()).select_from(User).where(User.status != "deleted")) or 0
    active_users = db.scalar(select(func.count()).select_from(User).where(User.status == "active")) or 0
    new_today = db.scalar(select(func.count()).select_from(User).where(func.date(User.created_at) == today)) or 0
    online_users = db.scalar(select(func.count()).select_from(User).where(User.is_online.is_(True))) or 0
    total_communities = db.scalar(select(func.count()).select_from(Community).where(Community.status != "deleted")) or 0
    open_reports = db.scalar(select(func.count()).select_from(Report).where(Report.status.in_(["open", "reviewing"]))) or 0
    pending_withdrawals = db.scalar(select(func.count()).select_from(WithdrawalRequest).where(WithdrawalRequest.status.in_(["pending", "under_review"]))) or 0
    pending_applications = db.scalar(select(func.count()).select_from(CreatorApplication).where(CreatorApplication.status == "submitted")) or 0
    total_coins_sold = db.scalar(
        select(func.coalesce(func.sum(WalletTransaction.amount), 0))
        .select_from(WalletTransaction)
        .where(WalletTransaction.transaction_type == "coin_purchase", WalletTransaction.status == "successful")
    ) or 0
    total_revenue = db.scalar(select(func.coalesce(func.sum(WalletTransaction.amount), 0)).select_from(WalletTransaction).where(WalletTransaction.transaction_type == "coin_purchase", WalletTransaction.status == "successful")) or 0

    # Calculate actual 7-day stats for charts
    from datetime import timedelta
    daily_stats = []
    for i in range(6, -1, -1):
        day_date = today - timedelta(days=i)
        
        users_count = db.scalar(
            select(func.count())
            .select_from(User)
            .where(func.date(User.created_at) == day_date, User.status != "deleted")
        ) or 0
        
        revenue_sum = db.scalar(
            select(func.coalesce(func.sum(WalletTransaction.amount), 0))
            .select_from(WalletTransaction)
            .where(
                func.date(WalletTransaction.created_at) == day_date,
                WalletTransaction.transaction_type == "coin_purchase",
                WalletTransaction.status == "successful"
            )
        ) or 0
        revenue_inr = int(revenue_sum / 100)
        
        reports_count = db.scalar(
            select(func.count())
            .select_from(Report)
            .where(func.date(Report.created_at) == day_date)
        ) or 0
        
        display_label = day_date.strftime("%b %d")
        daily_stats.append({
            "date": display_label,
            "users": users_count,
            "revenue": revenue_inr,
            "reports": reports_count,
        })

    return {
        "totalUsers": total_users,
        "activeUsers": active_users,
        "newUsersToday": new_today,
        "onlineUsers": online_users,
        "totalCommunities": total_communities,
        "openReports": open_reports,
        "pendingWithdrawals": pending_withdrawals,
        "pendingCreatorApplications": pending_applications,
        "totalCoinsSold": total_coins_sold,
        "totalRevenue": total_revenue,
        "dailyStats": daily_stats,
    }


# ── User Management ───────────────────────────────────────────────────────────

def list_users(
    db: DbSession,
    user: CurrentUser,
    search: str | None = None,
    status: str | None = None,
    role: str | None = None,
    skip: int = 0,
    limit: int = 50,
):
    require_admin(user)
    stmt = select(User)
    if status:
        stmt = stmt.where(User.status == status)
    if role:
        stmt = stmt.where(User.role == role)
    if search:
        like = f"%{search}%"
        from sqlalchemy import or_
        stmt = stmt.where(or_(User.name.ilike(like), User.email.ilike(like), User.username.ilike(like)))
    stmt = stmt.order_by(User.created_at.desc()).offset(skip).limit(min(limit, 200))
    rows = list(db.scalars(stmt))

    def _user_dict(u: User):
        return {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "username": u.username,
            "avatarUrl": u.avatar_url,
            "status": u.status,
            "role": u.role,
            "isVerified": u.is_verified,
            "isOnline": u.is_online,
            "city": u.city,
            "age": u.age,
            "createdAt": u.created_at,
            "lastActiveAt": u.last_active_at,
        }

    return [_user_dict(u) for u in rows]


def get_user(user_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    target = _require(db, User, user_id, "user")
    wallet = db.scalar(select(UserWallet).where(UserWallet.user_id == user_id))
    creator_profile = db.scalar(select(CreatorProfile).where(CreatorProfile.user_id == user_id))
    creator_app = db.scalar(select(CreatorApplication).where(CreatorApplication.user_id == user_id))
    return {
        "id": target.id,
        "name": target.name,
        "email": target.email,
        "username": target.username,
        "avatarUrl": target.avatar_url,
        "bio": target.bio,
        "city": target.city,
        "age": target.age,
        "gender": target.gender,
        "languages": target.languages,
        "interests": target.interests,
        "purposes": target.purposes,
        "status": target.status,
        "role": target.role,
        "isVerified": target.is_verified,
        "isOnline": target.is_online,
        "lastActiveAt": target.last_active_at,
        "createdAt": target.created_at,
        "wallet": {
            "purchasedCoins": wallet.purchased_coins if wallet else 0,
            "bonusCoins": wallet.bonus_coins if wallet else 0,
            "heldCoins": wallet.held_coins if wallet else 0,
        } if wallet else None,
        "isCreator": creator_profile is not None,
        "creatorApplication": {
            "status": creator_app.status,
            "submittedAt": creator_app.created_at,
        } if creator_app else None,
    }


def update_user(user_id: str, payload: UserStatusUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    target = _require(db, User, user_id, "user")
    if target.id == user.id:
        raise AppError(400, "cannot_modify_self", "Cannot change your own role/status.")
    target.status = payload.status
    if payload.role is not None:
        target.role = payload.role
    audit(db, user.id, f"admin.user.{payload.status}", "user", target.id, {"role": payload.role})
    db.commit()
    db.refresh(target)
    return {"id": target.id, "status": target.status, "role": target.role}


def delete_user(user_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    target = _require(db, User, user_id, "user")
    if target.id == user.id:
        raise AppError(400, "cannot_delete_self", "Cannot delete your own account via admin.")
    target.status = "deleted"
    target.email = f"deleted-{target.id}@invalid.local"
    target.name = "Deleted user"
    target.bio = ""
    target.avatar_url = None
    audit(db, user.id, "admin.user.deleted", "user", target.id)
    db.commit()
    return {"message": "User deleted."}


# ── Community Management ──────────────────────────────────────────────────────

def list_communities(
    db: DbSession,
    user: CurrentUser,
    search: str | None = None,
    status: str | None = None,
    skip: int = 0,
    limit: int = 50,
):
    require_admin(user)
    stmt = select(Community)
    if status:
        stmt = stmt.where(Community.status == status)
    if search:
        stmt = stmt.where(Community.name.ilike(f"%{search}%"))
    rows = list(db.scalars(stmt.order_by(Community.created_at.desc()).offset(skip).limit(min(limit, 200))))

    def _comm_dict(c: Community):
        owner = db.get(User, c.owner_id)
        return {
            "id": c.id,
            "name": c.name,
            "category": c.category,
            "privacy": c.privacy,
            "status": c.status,
            "memberCount": c.member_count,
            "ownerName": owner.name if owner else "Unknown",
            "ownerId": c.owner_id,
            "createdAt": c.created_at,
            "logoUrl": c.logo_url,
            "coverUrl": c.cover_url,
            "description": c.description,
            "premiumPrice": c.premium_price,
        }

    return [_comm_dict(c) for c in rows]


def update_community(community_id: str, payload: CommunityStatusUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    community = _require(db, Community, community_id, "community")
    old_status = community.status
    community.status = payload.status
    audit(db, user.id, f"admin.community.{payload.status}", "community", community.id)
    
    # Notify owner on status change
    if payload.status == "suspended" and old_status != "suspended":
        create_notification(
            db,
            community.owner_id,
            "system",
            "Community Suspended",
            f"Your community '{community.name}' has been suspended by an administrator."
        )
    elif payload.status == "active" and old_status == "suspended":
        create_notification(
            db,
            community.owner_id,
            "system",
            "Community Restored",
            f"Your community '{community.name}' has been re-activated by an administrator."
        )

    db.commit()
    return {"id": community.id, "status": community.status}


def delete_community(community_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    community = _require(db, Community, community_id, "community")
    community.status = "deleted"
    audit(db, user.id, "admin.community.deleted", "community", community.id)
    
    # Notify owner on deletion
    create_notification(
        db,
        community.owner_id,
        "system",
        "Community Deleted",
        f"Your community '{community.name}' has been deleted by an administrator."
    )

    db.commit()
    return {"message": "Community deleted."}


def list_community_members(community_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    _require(db, Community, community_id, "community")
    
    from app.modules.communities.models import CommunityMember
    stmt = select(CommunityMember).where(CommunityMember.community_id == community_id)
    members = db.scalars(stmt).all()
    
    results = []
    for m in members:
        u = db.get(User, m.user_id)
        if u:
            results.append({
                "id": u.id,
                "username": u.username,
                "name": u.name,
                "avatarUrl": u.avatar_url,
                "role": m.role,
                "joinedAt": m.created_at
            })
    return results


# ── Subscription Plans ────────────────────────────────────────────────────────

def list_subscription_plans(db: DbSession, user: CurrentUser):
    require_admin(user)
    return list(db.scalars(select(SubscriptionPlan).order_by(SubscriptionPlan.price_minor)))


def create_subscription_plan(payload: SubscriptionPlanCreate, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = SubscriptionPlan(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_subscription_plan(plan_id: str, payload: SubscriptionPlanUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, SubscriptionPlan, plan_id, "subscription_plan")
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(item, k, v)
    db.commit()
    db.refresh(item)
    return item


def delete_subscription_plan(plan_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, SubscriptionPlan, plan_id, "subscription_plan")
    item.active = False
    db.commit()
    return {"message": "Plan deactivated."}


# ── Coin Packages ─────────────────────────────────────────────────────────────

def list_coin_packages(db: DbSession, user: CurrentUser):
    require_admin(user)
    return list(db.scalars(select(CoinPackage).order_by(CoinPackage.price_minor)))


def create_coin_package(payload: CoinPackageCreate, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = CoinPackage(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_coin_package(package_id: str, payload: CoinPackageUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, CoinPackage, package_id, "coin_package")
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(item, k, v)
    db.commit()
    db.refresh(item)
    return item


# ── Special Offers ────────────────────────────────────────────────────────────

def list_offers(db: DbSession, user: CurrentUser):
    require_admin(user)
    from app.modules.commerce.models import SpecialOffer
    return list(db.scalars(select(SpecialOffer).order_by(SpecialOffer.created_at.desc())))


def create_offer(payload: SpecialOfferCreate, db: DbSession, user: CurrentUser):
    require_admin(user)
    from app.modules.commerce.models import SpecialOffer
    item = SpecialOffer(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_offer(offer_id: str, payload: SpecialOfferUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    from app.modules.commerce.models import SpecialOffer
    item = _require(db, SpecialOffer, offer_id, "special_offer")
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(item, k, v)
    db.commit()
    db.refresh(item)
    return item


def delete_offer(offer_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    from app.modules.commerce.models import SpecialOffer
    item = _require(db, SpecialOffer, offer_id, "special_offer")
    db.delete(item)
    db.commit()
    return {"message": "Offer deleted."}


# ── Creator Applications ──────────────────────────────────────────────────────

def list_creator_applications(db: DbSession, user: CurrentUser, status: str | None = None):
    require_admin(user)
    stmt = select(CreatorApplication)
    if status:
        stmt = stmt.where(CreatorApplication.status == status)
    rows = list(db.scalars(stmt.order_by(CreatorApplication.created_at.desc()).limit(200)))

    def _app_dict(a: CreatorApplication):
        u = db.get(User, a.user_id)
        return {
            "id": a.id,
            "userId": a.user_id,
            "userName": u.name if u else "Unknown",
            "userEmail": u.email if u else "",
            "avatarUrl": u.avatar_url if u else None,
            "status": a.status,
            "languages": a.languages,
            "topics": a.topics,
            "experience": a.experience,
            "introduction": a.introduction,
            "chatAvailable": a.chat_available,
            "audioAvailable": a.audio_available,
            "videoAvailable": a.video_available,
            "reviewNote": a.review_note,
            "submittedAt": a.created_at,
            "reviewedAt": a.reviewed_at,
        }

    return [_app_dict(a) for a in rows]


def review_creator_application(application_id: str, payload: CreatorApplicationReview, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, CreatorApplication, application_id, "creator_application")
    item.status = "approved" if payload.action == "approve" else "rejected"
    item.review_note = payload.note
    item.reviewed_by = user.id
    item.reviewed_at = datetime.now(UTC)
    if payload.action == "approve":
        # Create creator profile if not exists
        existing = db.scalar(select(CreatorProfile).where(CreatorProfile.user_id == item.user_id))
        if not existing:
            profile = CreatorProfile(
                user_id=item.user_id,
                topics=item.topics,
                languages=item.languages,
                introduction=item.introduction,
                chat_available=item.chat_available,
                audio_available=item.audio_available,
                video_available=item.video_available,
            )
            db.add(profile)
        target_user = db.get(User, item.user_id)
        if target_user:
            target_user.is_verified = True
    audit(db, user.id, f"admin.creator_application.{payload.action}", "creator_application", item.id, {"note": payload.note})
    db.commit()
    return {"id": item.id, "status": item.status}


# ── Withdrawals ───────────────────────────────────────────────────────────────

def list_withdrawals(db: DbSession, user: CurrentUser, status: str | None = None, skip: int = 0, limit: int = 50):
    require_admin(user)
    stmt = select(WithdrawalRequest)
    if status:
        stmt = stmt.where(WithdrawalRequest.status == status)
    rows = list(db.scalars(stmt.order_by(WithdrawalRequest.created_at.desc()).offset(skip).limit(min(limit, 200))))

    def _wd_dict(w: WithdrawalRequest):
        u = db.get(User, w.creator_id)
        return {
            "id": w.id,
            "creatorId": w.creator_id,
            "creatorName": u.name if u else "Unknown",
            "creatorEmail": u.email if u else "",
            "amount": w.amount,
            "payoutAccountReference": w.payout_account_reference,
            "status": w.status,
            "failureReason": w.failure_reason,
            "processedAt": w.processed_at,
            "createdAt": w.created_at,
        }

    return [_wd_dict(w) for w in rows]


def review_withdrawal(withdrawal_id: str, payload: WithdrawalReview, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, WithdrawalRequest, withdrawal_id, "withdrawal")
    if item.status in {"paid", "rejected", "failed"}:
        raise AppError(409, "withdrawal_closed", "This withdrawal is already closed.")
    transitions = {
        "pending": {"under_review", "rejected"},
        "under_review": {"approved", "rejected"},
        "approved": {"processing", "rejected"},
        "processing": {"paid", "failed"},
    }
    if payload.status not in transitions.get(item.status, set()):
        raise AppError(409, "invalid_withdrawal_transition", f"Cannot move withdrawal from {item.status} to {payload.status}.")
    wallet = creator_service.wallet_for(db, item.creator_id)
    if payload.status in {"rejected", "failed"}:
        wallet.available_earnings += item.amount
        item.failure_reason = payload.reason
    elif payload.status == "paid":
        wallet.withdrawn_earnings += item.amount
        item.processed_at = datetime.now(UTC)
    item.status = payload.status
    create_notification(db, item.creator_id, "withdrawal_update", "Withdrawal updated", f"Your withdrawal is now {payload.status.replace('_', ' ')}.", {"screen": "Withdrawal", "withdrawalId": item.id})
    audit(db, user.id, f"withdrawal.{payload.status}", "withdrawal", item.id)
    db.commit()
    db.refresh(item)
    return item


def _enrich_report(db: DbSession, report: Report) -> dict:
    from app.modules.users.models import User
    from app.modules.feed.models import Post, Comment
    from app.modules.communities.models import Community
    from app.modules.chat.models import Message

    data = {
        "id": report.id,
        "reporter_id": report.reporter_id,
        "target_type": report.target_type,
        "target_id": report.target_id,
        "reason": report.reason,
        "details": report.details,
        "evidence_ids": report.evidence_ids,
        "status": report.status,
        "created_at": report.created_at,
        "reporter": None,
        "target": None
    }

    reporter = db.get(User, report.reporter_id)
    if reporter:
        data["reporter"] = {
            "id": reporter.id,
            "username": reporter.username,
            "name": reporter.name,
            "avatar_url": reporter.avatar_url,
            "email": reporter.email
        }

    if report.target_type == "user":
        t_user = db.get(User, report.target_id)
        if t_user:
            data["target"] = {
                "id": t_user.id,
                "type": "user",
                "display_name": f"@{t_user.username} ({t_user.name})",
                "details": f"Bio: {t_user.bio or 'N/A'}",
                "avatar_url": t_user.avatar_url
            }
    elif report.target_type == "post":
        t_post = db.get(Post, report.target_id)
        if t_post:
            author = db.get(User, t_post.author_id)
            display_name = f"Post by @{author.username}" if author else "Post by Unknown"
            data["target"] = {
                "id": t_post.id,
                "type": "post",
                "display_name": display_name,
                "details": t_post.body,
                "media_url": t_post.media_url,
                "author_id": t_post.author_id,
                "author": {
                    "username": author.username,
                    "name": author.name,
                    "avatar_url": author.avatar_url
                } if author else None
            }
    elif report.target_type == "comment":
        t_comment = db.get(Comment, report.target_id)
        if t_comment:
            author = db.get(User, t_comment.author_id)
            display_name = f"Comment by @{author.username}" if author else "Comment by Unknown"
            data["target"] = {
                "id": t_comment.id,
                "type": "comment",
                "display_name": display_name,
                "details": t_comment.body,
                "author_id": t_comment.author_id,
                "author": {
                    "username": author.username,
                    "name": author.name,
                    "avatar_url": author.avatar_url
                } if author else None
            }
    elif report.target_type == "community":
        t_comm = db.get(Community, report.target_id)
        if t_comm:
            owner = db.get(User, t_comm.owner_id)
            display_name = f"Community: {t_comm.name}"
            data["target"] = {
                "id": t_comm.id,
                "type": "community",
                "display_name": display_name,
                "details": t_comm.description,
                "logo_url": t_comm.logo_url,
                "cover_url": t_comm.cover_url,
                "owner": {
                    "username": owner.username,
                    "name": owner.name
                } if owner else None
            }
    elif report.target_type == "message":
        t_msg = db.get(Message, report.target_id)
        if t_msg:
            sender = db.get(User, t_msg.sender_id)
            display_name = f"Message from @{sender.username}" if sender else "Message from Unknown"
            data["target"] = {
                "id": t_msg.id,
                "type": "message",
                "display_name": display_name,
                "details": t_msg.text,
                "media_url": t_msg.media_url,
                "sender": {
                    "username": sender.username,
                    "name": sender.name,
                    "avatar_url": sender.avatar_url
                } if sender else None
            }

    if not data["target"]:
        data["target"] = {
            "id": report.target_id,
            "type": report.target_type,
            "display_name": f"Target ID: {report.target_id[:8]}... (Type: {report.target_type})",
            "details": "Target content could not be found or has been deleted."
        }

    return data


def list_reports(db: DbSession, user: CurrentUser):
    require_admin(user)
    reports = db.scalars(select(Report).order_by(Report.created_at.desc()).limit(200)).all()
    return [_enrich_report(db, r) for r in reports]


def _get_reported_user_id(db: DbSession, target_type: str, target_id: str) -> str | None:
    from app.modules.users.models import User
    from app.modules.feed.models import Post, Comment
    from app.modules.communities.models import Community
    from app.modules.chat.models import Message

    if target_type == "user":
        return target_id
    elif target_type == "post":
        post = db.get(Post, target_id)
        return post.author_id if post else None
    elif target_type == "comment":
        comment = db.get(Comment, target_id)
        return comment.author_id if comment else None
    elif target_type == "community":
        comm = db.get(Community, target_id)
        return comm.owner_id if comm else None
    elif target_type == "message":
        msg = db.get(Message, target_id)
        return msg.sender_id if msg else None
    return None


def review_report(report_id: str, payload: ReportReview, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, Report, report_id, "report")
    item.status = payload.status
    if item.target_type == "user" and payload.action in {"restrict", "suspend", "ban"}:
        target = db.get(User, item.target_id)
        if target:
            target.status = payload.action
    if payload.action == "remove_content":
        from app.modules.chat.models import Message
        from app.modules.communities.models import Community
        from app.modules.engagement.models import RatingReview
        from app.modules.feed.models import Comment, Post, Story
        if item.target_type == "post" and (target := db.get(Post, item.target_id)): target.status = "removed"
        elif item.target_type == "comment" and (target := db.get(Comment, item.target_id)): target.status = "removed"
        elif item.target_type == "message" and (target := db.get(Message, item.target_id)): target.is_deleted = True; target.text = ""
        elif item.target_type == "story" and (target := db.get(Story, item.target_id)): db.delete(target)
        elif item.target_type == "community" and (target := db.get(Community, item.target_id)): target.status = "suspended"
        elif item.target_type == "rating" and (target := db.get(RatingReview, item.target_id)): target.status = "removed"
    
    # 1. Notify the Reporter
    reporter_msg = "Your report has been reviewed."
    if payload.status == "dismissed":
        reporter_msg = "Your report was reviewed. After investigation, no violations were found. Thank you for keeping our community safe."
    elif payload.status == "resolved":
        action_label = payload.action.replace('_', ' ')
        reporter_msg = f"Your report was resolved. Action '{action_label}' has been taken regarding the reported content/user."
        
    create_notification(
        db,
        item.reporter_id,
        "system",
        "Report Review Update",
        reporter_msg,
        {"report_id": item.id, "status": payload.status}
    )

    # 2. Notify the Reported User (if action was taken)
    reported_user_id = _get_reported_user_id(db, item.target_type, item.target_id)
    if reported_user_id and payload.action != "none":
        reported_title = "Moderation Notice"
        if payload.action == "warn":
            reported_body = f"Warning: You received a formal warning regarding your reported '{item.target_type}'."
        elif payload.action == "restrict":
            reported_body = "Your account has been restricted due to community guidelines violations."
        elif payload.action == "suspend":
            reported_body = "Your account has been suspended due to community guidelines violations."
        elif payload.action == "ban":
            reported_body = "Your account has been permanently banned due to severe guidelines violations."
        elif payload.action == "remove_content":
            reported_body = f"Content Removed: Your reported '{item.target_type}' has been removed for violating guidelines."
        else:
            reported_body = f"Action '{payload.action}' has been taken on your account due to report violations."

        create_notification(
            db,
            reported_user_id,
            "system",
            reported_title,
            reported_body,
            {"report_id": item.id, "action": payload.action, "target_type": item.target_type}
        )

    audit(db, user.id, f"report.{payload.action}", item.target_type, item.target_id, {"report_id": item.id})
    db.commit()
    return _enrich_report(db, item)


def list_audit_logs(db: DbSession, user: CurrentUser):
    require_admin(user)
    return list(db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc()).limit(200)))


# ── Support Articles ──────────────────────────────────────────────────────────

def list_support_articles(db: DbSession, user: CurrentUser):
    require_admin(user)
    return list(db.scalars(select(SupportArticle).order_by(SupportArticle.position)))


def create_support_article(payload: SupportArticleCreate, db: DbSession, user: CurrentUser):
    require_admin(user)
    existing = db.scalar(select(SupportArticle).where(SupportArticle.slug == payload.slug))
    if existing:
        raise AppError(409, "slug_exists", "An article with this slug already exists.")
    item = SupportArticle(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_support_article(article_id: str, payload: SupportArticleUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, SupportArticle, article_id, "support_article")
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(item, k, v)
    db.commit()
    db.refresh(item)
    return item


def delete_support_article(article_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, SupportArticle, article_id, "support_article")
    db.delete(item)
    db.commit()
    return {"message": "Article deleted."}


# ── Platform Settings ─────────────────────────────────────────────────────────

def get_settings(db: DbSession, user: CurrentUser):
    require_admin(user)
    return {
        # Coin rates
        "chatCoinsPerMinute": settings.chat_coins_per_minute,
        "audioCoinsPerMinute": settings.audio_coins_per_minute,
        "videoCoinsPerMinute": settings.video_coins_per_minute,
        # Paid chat per-message deduction
        "chatCoinsPerMessage": settings.chat_coins_per_message,
        "chatMessageDeductionInterval": settings.chat_message_deduction_interval,
        # Private content
        "privatePostCoinPrice": settings.private_post_coin_price,
        "privateCommunityCoins": settings.private_community_coin_price,
        # Conversation limits
        "freeConversationsPerWeek": settings.free_conversations_per_week,
        "freeMessagesPerConversation": settings.free_messages_per_conversation,
        "messageRequestsPerDay": settings.message_requests_per_day,
        "messageRequestExpiryHours": settings.message_request_expiry_hours,
        # Platform financials
        "platformCommissionPercent": settings.platform_commission_percent,
        "creatorSettlementDays": settings.creator_settlement_days,
        # Rewards
        "dailyLoginRewardSchedule": settings.daily_login_reward_schedule,
        "referralInviterCoins": settings.referral_inviter_coins,
        "referralInviteeCoins": settings.referral_invitee_coins,
        # Post/Community pricing
        "postPriceMinCoins": settings.post_price_min_coins,
        "postPriceMaxCoins": settings.post_price_max_coins,
        "communityPriceMinCoins": settings.community_price_min_coins,
        "communityPriceMaxCoins": settings.community_price_max_coins,
        "communitySubscriptionDays": settings.community_subscription_days,
        # Post boosting
        "postBoostCoins": settings.post_boost_coins,
        "postBoostHours": settings.post_boost_hours,
        # Bounty
        "bountyMinCoins": settings.bounty_min_coins,
        # Call settings
        "callGracePeriodSeconds": settings.call_grace_period_seconds,
        "callRingTimeoutSeconds": settings.call_ring_timeout_seconds,
        "callJoinTimeoutSeconds": settings.call_join_timeout_seconds,
        "callDurationOptions": settings.call_duration_options,
        "paidChatDurationOptions": settings.paid_chat_duration_options,
        # Safety & toggles
        "restrictedWords": settings.restricted_words,
        "dummyPaymentsEnabled": settings.dummy_payments_enabled,
        # Post creation charging
        "postDeductionEnabled": settings.post_deduction_enabled,
        "publicPostPriceCoins": settings.public_post_price_coins,
        "privatePostPriceCoins": settings.private_post_price_coins,
    }


def update_settings(payload: PlatformSettingsUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    changes = payload.model_dump(exclude_none=True)
    env_map = {
        # Coin rates
        "chat_coins_per_minute": "CHAT_COINS_PER_MINUTE",
        "audio_coins_per_minute": "AUDIO_COINS_PER_MINUTE",
        "video_coins_per_minute": "VIDEO_COINS_PER_MINUTE",
        # Paid chat per-message
        "chat_coins_per_message": "CHAT_COINS_PER_MESSAGE",
        "chat_message_deduction_interval": "CHAT_MESSAGE_DEDUCTION_INTERVAL",
        # Private content
        "private_post_coin_price": "PRIVATE_POST_COIN_PRICE",
        "private_community_coin_price": "PRIVATE_COMMUNITY_COIN_PRICE",
        # Conversation limits
        "free_conversations_per_week": "FREE_CONVERSATIONS_PER_WEEK",
        "free_messages_per_conversation": "FREE_MESSAGES_PER_CONVERSATION",
        "message_requests_per_day": "MESSAGE_REQUESTS_PER_DAY",
        "message_request_expiry_hours": "MESSAGE_REQUEST_EXPIRY_HOURS",
        # Financials
        "platform_commission_percent": "PLATFORM_COMMISSION_PERCENT",
        "creator_settlement_days": "CREATOR_SETTLEMENT_DAYS",
        # Rewards
        "daily_login_reward_schedule": "DAILY_LOGIN_REWARD_SCHEDULE",
        "referral_inviter_coins": "REFERRAL_INVITER_COINS",
        "referral_invitee_coins": "REFERRAL_INVITEE_COINS",
        # Post/Community pricing
        "post_price_min_coins": "POST_PRICE_MIN_COINS",
        "post_price_max_coins": "POST_PRICE_MAX_COINS",
        "community_price_min_coins": "COMMUNITY_PRICE_MIN_COINS",
        "community_price_max_coins": "COMMUNITY_PRICE_MAX_COINS",
        "community_subscription_days": "COMMUNITY_SUBSCRIPTION_DAYS",
        # Boosting
        "post_boost_coins": "POST_BOOST_COINS",
        "post_boost_hours": "POST_BOOST_HOURS",
        # Bounty
        "bounty_min_coins": "BOUNTY_MIN_COINS",
        # Call settings
        "call_grace_period_seconds": "CALL_GRACE_PERIOD_SECONDS",
        "call_ring_timeout_seconds": "CALL_RING_TIMEOUT_SECONDS",
        "call_join_timeout_seconds": "CALL_JOIN_TIMEOUT_SECONDS",
        "call_duration_options": "CALL_DURATION_OPTIONS",
        "paid_chat_duration_options": "PAID_CHAT_DURATION_OPTIONS",
        # Safety
        "restricted_words": "RESTRICTED_WORDS",
        "dummy_payments_enabled": "DUMMY_PAYMENTS_ENABLED",
        # Post creation charging
        "post_deduction_enabled": "POST_DEDUCTION_ENABLED",
        "public_post_price_coins": "PUBLIC_POST_PRICE_COINS",
        "private_post_price_coins": "PRIVATE_POST_PRICE_COINS",
    }
    # Apply changes to the in-memory settings object and persist to database
    from app.modules.app_content.models import SystemSetting
    from sqlalchemy import select

    for key, value in changes.items():
        if hasattr(settings, key):
            object.__setattr__(settings, key, value)
            
            # Stringify value to save in DB
            if isinstance(value, list):
                db_val = ",".join(str(x) for x in value)
            elif isinstance(value, bool):
                db_val = str(value).lower()
            else:
                db_val = str(value)
                
            # Upsert in database
            db_setting = db.scalar(select(SystemSetting).where(SystemSetting.key == key))
            if db_setting:
                db_setting.value = db_val
            else:
                db.add(SystemSetting(key=key, value=db_val))

    audit(db, user.id, "admin.settings.updated", "settings", "global", changes)
    db.commit()
    return get_settings(db, user)


# ── Transactions ──────────────────────────────────────────────────────────────

def list_transactions(
    db: DbSession,
    user: CurrentUser,
    user_id: str | None = None,
    transaction_type: str | None = None,
    skip: int = 0,
    limit: int = 50,
):
    require_admin(user)
    stmt = select(WalletTransaction)
    if user_id:
        from sqlalchemy import or_
        # Look up user dynamically by email, username, or id
        u_match = db.scalar(
            select(User.id).where(
                or_(
                    User.id == user_id,
                    User.email.ilike(user_id),
                    User.username.ilike(user_id)
                )
            )
        )
        if u_match:
            stmt = stmt.where(WalletTransaction.user_id == u_match)
        else:
            stmt = stmt.where(WalletTransaction.user_id == "not_found_uid")
    if transaction_type:
        stmt = stmt.where(WalletTransaction.transaction_type == transaction_type)
    
    rows = list(db.scalars(stmt.order_by(WalletTransaction.created_at.desc()).offset(skip).limit(min(limit, 200))))
    
    def _tx_dict(t: WalletTransaction):
        target_user = db.get(User, t.user_id)
        return {
            "id": t.id,
            "userId": t.user_id,
            "userName": target_user.name if target_user else "Unknown",
            "userEmail": target_user.email if target_user else "",
            "transactionType": t.transaction_type,
            "balanceType": t.balance_type,
            "amount": t.amount,
            "status": t.status,
            "referenceType": t.reference_type,
            "referenceId": t.reference_id,
            "paymentMethod": t.payment_method,
            "createdAt": t.created_at,
        }
    return [_tx_dict(t) for t in rows]


# ── Revenue Summary ───────────────────────────────────────────────────────────

def revenue_summary(db: DbSession, user: CurrentUser, period: str = "30d"):
    from datetime import timedelta
    from app.modules.creators.models import CreatorTransaction
    require_admin(user)
    days_map = {"7d": 7, "30d": 30, "90d": 90, "all": None}
    if period not in days_map:
        raise AppError(422, "invalid_period", "Choose 7d, 30d, 90d, or all.")
    days = days_map[period]
    since = datetime.now(UTC) - timedelta(days=days) if days else None

    # Coin purchase revenue: sum of all coin purchases (price paid, not coins)
    coin_stmt = select(WalletTransaction).where(WalletTransaction.transaction_type == "coin_purchase", WalletTransaction.status == "successful")
    if since:
        coin_stmt = coin_stmt.where(WalletTransaction.created_at >= since)
    coin_txns = list(db.scalars(coin_stmt))
    # Coin revenue: match back to packages via reference_id
    from app.modules.commerce.models import CoinPackage
    coin_revenue = 0
    coin_purchase_count = len([t for t in coin_txns if t.balance_type == "purchased_coins"])
    for txn in coin_txns:
        if txn.reference_type == "coin_package" and txn.reference_id:
            pkg = db.get(CoinPackage, txn.reference_id)
            if pkg:
                coin_revenue += pkg.price_minor

    # Commission earned: sum of commission_amount from all creator transactions
    comm_stmt = select(CreatorTransaction)
    if since:
        comm_stmt = comm_stmt.where(CreatorTransaction.created_at >= since)
    creator_txns = list(db.scalars(comm_stmt))
    commission_total = sum(t.commission_amount for t in creator_txns)
    paid_session_count = len(creator_txns)

    # Total platform revenue
    total_revenue_paise = coin_revenue
    total_revenue = total_revenue_paise / 100  # convert to rupees

    # Daily breakdown for chart
    chart_days = days or 30
    daily: dict[str, dict] = {}
    for offset in range(chart_days - 1, -1, -1):
        key = (datetime.now(UTC) - timedelta(days=offset)).date().isoformat()
        daily[key] = {"date": key, "subscriptionRevenue": 0, "coinRevenue": 0, "commission": 0}
    for txn in coin_txns:
        key = txn.created_at.date().isoformat()
        if key in daily and txn.reference_type == "coin_package" and txn.reference_id:
            pkg = db.get(CoinPackage, txn.reference_id)
            if pkg:
                daily[key]["coinRevenue"] += round(pkg.price_minor / 100, 2)
    for txn in creator_txns:
        key = txn.created_at.date().isoformat()
        if key in daily:
            daily[key]["commission"] += txn.commission_amount

    # Top creators by earnings
    from sqlalchemy import func as sqlfunc
    top_creators_rows = list(db.execute(
        select(CreatorTransaction.creator_id, sqlfunc.sum(CreatorTransaction.creator_amount).label("total_earned"))
        .group_by(CreatorTransaction.creator_id)
        .order_by(sqlfunc.sum(CreatorTransaction.creator_amount).desc())
        .limit(10)
    ))
    top_creators = []
    for row in top_creators_rows:
        u = db.get(User, row.creator_id)
        top_creators.append({
            "userId": row.creator_id,
            "name": u.name if u else "Unknown",
            "avatarUrl": u.avatar_url if u else None,
            "totalEarned": row.total_earned,
        })

    return {
        "period": period,
        "totalRevenue": round(total_revenue, 2),
        "subscriptionRevenue": 0,
        "coinPurchaseRevenue": round(coin_revenue / 100, 2),
        "commissionEarned": commission_total,
        "subscriptionsSold": 0,
        "coinPackagesSold": coin_purchase_count,
        "paidSessionCount": paid_session_count,
        "activeSubscriptionsNow": 0,
        "chart": list(daily.values()),
        "topCreators": top_creators,
        "commissionPercent": settings.platform_commission_percent,
    }


# ── Virtual Gifts CRUD ────────────────────────────────────────────────────────

def list_virtual_gifts(db: DbSession, user: CurrentUser):
    require_admin(user)
    return list(db.scalars(select(VirtualGift).order_by(VirtualGift.coin_price)))


def create_virtual_gift(payload: VirtualGiftCreate, db: DbSession, user: CurrentUser):
    require_admin(user)
    existing = db.scalar(select(VirtualGift).where(VirtualGift.name == payload.name))
    if existing:
        raise AppError(409, "gift_exists", "A virtual gift with this name already exists.")
    item = VirtualGift(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_virtual_gift(gift_id: str, payload: VirtualGiftUpdate, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, VirtualGift, gift_id, "virtual_gift")
    for k, v in payload.model_dump(exclude_none=True).items():
        setattr(item, k, v)
    db.commit()
    db.refresh(item)
    return item


def delete_virtual_gift(gift_id: str, db: DbSession, user: CurrentUser):
    require_admin(user)
    item = _require(db, VirtualGift, gift_id, "virtual_gift")
    item.active = False
    db.commit()
    return {"message": "Virtual gift deactivated."}


def referral_stats(db: DbSession, user: CurrentUser):
    """Admin: overall referral program stats."""
    require_admin(user)
    total_referred = db.scalar(
        select(func.count()).select_from(User).where(User.referred_by.isnot(None))
    ) or 0
    total_referrers = db.scalar(
        select(func.count(func.distinct(User.referred_by))).select_from(User).where(User.referred_by.isnot(None))
    ) or 0
    total_coins_awarded = total_referred * settings.referral_inviter_coins + total_referred * settings.referral_invitee_coins
    return {
        "totalReferred": total_referred,
        "totalReferrers": total_referrers,
        "totalCoinsAwarded": total_coins_awarded,
        "rewardPerReferral": settings.referral_inviter_coins,
        "inviteeBonus": settings.referral_invitee_coins,
    }


def top_referrers(db: DbSession, user: CurrentUser):
    """Admin: top users ranked by number of referrals made."""
    require_admin(user)
    rows = db.execute(
        select(User.referred_by, func.count().label("count"))
        .where(User.referred_by.isnot(None))
        .group_by(User.referred_by)
        .order_by(func.count().desc())
        .limit(20)
    ).all()
    result = []
    for row in rows:
        referrer = db.get(User, row.referred_by)
        if referrer:
            result.append({
                "id": referrer.id,
                "name": referrer.name,
                "email": referrer.email,
                "avatarUrl": referrer.avatar_url,
                "referralCode": referrer.referral_code,
                "referralCount": row.count,
                "coinsEarned": row.count * settings.referral_inviter_coins,
            })
    return result

