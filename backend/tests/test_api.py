from fastapi.testclient import TestClient

from app.main import app
from app.core.database import Base, engine
from app.core.database import SessionLocal
from app.core.seed import seed_app_content
from app.modules.users.models import User
from app.modules.creators.models import CreatorProfile, CreatorTransaction
from app.modules.chat.models import MessageRequest
from datetime import UTC, datetime, timedelta
from sqlalchemy import select


Base.metadata.create_all(bind=engine)
with SessionLocal() as seed_db:
    seed_app_content(seed_db)
client = TestClient(app)


def auth_headers(email="test@example.com"):
    response = client.post(
        "/api/v1/auth/register",
        json={"name": "Test User", "age": 24, "email": email, "password": "password123"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}, response.json()


def approved_conversation(sender_headers, recipient_headers, recipient_id):
    plan = client.get("/api/v1/subscriptions/plans", headers=sender_headers).json()[0]
    subscribed = client.post(
        "/api/v1/subscriptions/purchase",
        headers=sender_headers,
        json={"plan_id": plan["id"], "purchase_token": f"dummy_plan_{recipient_id}"},
    )
    assert subscribed.status_code == 201, subscribed.text
    package = client.get("/api/v1/wallet/coin-packages", headers=sender_headers).json()[0]
    purchased = client.post(
        "/api/v1/wallet/buy-coins",
        headers=sender_headers,
        json={"package_id": package["id"], "purchase_token": f"dummy_coins_{recipient_id}"},
    )
    assert purchased.status_code == 201, purchased.text
    requested = client.post(
        "/api/v1/chat/message-requests",
        headers=sender_headers,
        json={"recipient_id": recipient_id, "introduction": "Hello, I would like to connect respectfully."},
    )
    assert requested.status_code == 201, requested.text
    accepted = client.patch(
        f"/api/v1/chat/message-requests/{requested.json()['id']}",
        headers=recipient_headers,
        json={"action": "accept"},
    )
    assert accepted.status_code == 200, accepted.text
    return {"id": accepted.json()["conversationId"]}


def test_health_and_openapi():
    assert client.get("/health").json()["status"] == "ok"
    assert len(client.get("/openapi.json").json()["paths"]) >= 60


def test_private_chat_message_usage_is_counted_per_sender_only():
    sender_headers, _ = auth_headers("sender-message-limit@example.com")
    receiver_headers, _ = auth_headers("receiver-message-limit@example.com")
    receiver = client.get("/api/v1/users/me", headers=receiver_headers).json()
    conversation = approved_conversation(sender_headers, receiver_headers, receiver["id"])

    plan = client.get("/api/v1/subscriptions/plans", headers=receiver_headers).json()[0]
    subscribed = client.post(
        "/api/v1/subscriptions/purchase",
        headers=receiver_headers,
        json={"plan_id": plan["id"], "purchase_token": "dummy_receiver_message_limit_plan"},
    )
    assert subscribed.status_code == 201, subscribed.text

    for index in range(5):
        sent = client.post(
            f"/api/v1/chat/conversations/{conversation['id']}/messages",
            headers=sender_headers,
            json={"text": f"Sender message {index + 1}"},
        )
        assert sent.status_code == 201, sent.text

    with SessionLocal() as db:
        paid_session = db.scalar(
            select(MessageRequest).where(MessageRequest.conversation_id == conversation["id"])
        )
        paid_session.accepted_at = datetime.now(UTC) - timedelta(minutes=11)
        db.commit()

    reply = client.post(
        f"/api/v1/chat/conversations/{conversation['id']}/messages",
        headers=receiver_headers,
        json={"text": "Receiver's first reply"},
    )
    assert reply.status_code == 201, reply.text

    expired_sender_message = client.post(
        f"/api/v1/chat/conversations/{conversation['id']}/messages",
        headers=sender_headers,
        json={"text": "This sender session is expired"},
    )
    assert expired_sender_message.status_code == 402, expired_sender_message.text

    sender_limits = client.get(
        "/api/v1/chat/limits", headers=sender_headers, params={"conversation_id": conversation["id"]}
    ).json()
    receiver_limits = client.get(
        "/api/v1/chat/limits", headers=receiver_headers, params={"conversation_id": conversation["id"]}
    ).json()
    assert sender_limits["conversationMessageUsed"] == 5
    assert receiver_limits["conversationMessageUsed"] == 1


def test_access_passes_are_day_week_and_month_only():
    headers, _ = auth_headers("plans@example.com")
    plans = client.get("/api/v1/subscriptions/plans", headers=headers).json()
    assert [plan["interval"] for plan in plans] == ["day", "week", "month"]


def test_auth_profile_refresh_and_public_privacy():
    headers, token = auth_headers()
    me = client.get("/api/v1/users/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["email"] == "test@example.com"
    public = client.get(f"/api/v1/users/{me.json()['id']}", headers=headers)
    assert public.status_code == 200
    assert "email" not in public.json()
    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": token["refresh_token"]})
    assert refreshed.status_code == 200


def test_community_feed_and_safety_flows():
    headers, _ = auth_headers("owner@example.com")
    community = client.post(
        "/api/v1/communities",
        headers=headers,
        json={
            "name": "API Builders",
            "category": "Technology",
            "description": "A safe community for API builders.",
            "rules": ["Be kind"],
        },
    )
    assert community.status_code == 201, community.text
    community_id = community.json()["id"]
    post = client.post(
        "/api/v1/feed/posts",
        headers=headers,
        json={"community_id": community_id, "type": "poll", "body": "Which API style?", "poll_options": ["REST", "GraphQL"]},
    )
    assert post.status_code == 201, post.text
    post_id = post.json()["id"]
    assert client.post(f"/api/v1/feed/posts/{post_id}/comments", headers=headers, json={"body": "REST for this app"}).status_code == 201
    assert client.post(f"/api/v1/feed/posts/{post_id}/like", headers=headers).json()["liked"] is True
    assert client.post(f"/api/v1/feed/posts/{post_id}/save", headers=headers).json()["saved"] is True
    report = client.post("/api/v1/safety/reports", headers=headers, json={"target_type": "post", "target_id": post_id, "reason": "Test report"})
    assert report.status_code == 201


def test_private_and_community_websocket_events_persist():
    first_headers, first_token = auth_headers("socket-one@example.com")
    second_headers, second_token = auth_headers("socket-two@example.com")
    second_user = client.get("/api/v1/users/me", headers=second_headers).json()
    conversation = approved_conversation(first_headers, second_headers, second_user["id"])
    with client.websocket_connect(
        f"/api/v1/chat/ws/{conversation['id']}?token={first_token['access_token']}"
    ) as socket:
        assert socket.receive_json()["event"] == "presence"
        socket.send_json({"event": "typing", "typing": True})
        socket.send_json(
            {"event": "message", "client_id": "local-1", "data": {"text": "Live hello"}}
        )
        event = socket.receive_json()
        assert event["event"] == "message"
        assert event["message"]["text"] == "Live hello"
    history = client.get(
        f"/api/v1/chat/conversations/{conversation['id']}/messages", headers=first_headers
    )
    assert history.json()[-1]["text"] == "Live hello"

    community = client.post(
        "/api/v1/communities",
        headers=first_headers,
        json={
            "name": "Realtime Community",
            "category": "Technology",
            "description": "Community used to test realtime chat.",
        },
    ).json()
    with client.websocket_connect(
        f"/api/v1/communities/ws/{community['id']}?token={first_token['access_token']}"
    ) as socket:
        assert socket.receive_json()["event"] == "presence"
        socket.send_json(
            {"event": "message", "client_id": "community-local", "data": {"text": "Group hello"}}
        )
        assert socket.receive_json()["message"]["text"] == "Group hello"


def test_connect_requires_both_users_to_accept():
    first_headers, _ = auth_headers("match-one@example.com")
    second_headers, _ = auth_headers("match-two@example.com")
    preferences = {
        "purpose": "Talk",
        "language": "English",
        "min_age": 18,
        "max_age": 35,
        "anonymous": False,
    }
    first = client.post("/api/v1/matching/start", headers=first_headers, json=preferences)
    assert first.status_code == 201, first.text
    assert first.json()["status"] == "searching"
    second = client.post("/api/v1/matching/start", headers=second_headers, json=preferences)
    assert second.status_code == 201, second.text
    match_id = second.json()["id"]
    assert second.json()["status"] == "found"
    first_accept = client.post(f"/api/v1/matching/{match_id}/accept", headers=first_headers)
    assert first_accept.json()["status"] == "waiting"
    assert first_accept.json()["conversation_id"] is None
    second_accept = client.post(f"/api/v1/matching/{match_id}/accept", headers=second_headers)
    assert second_accept.json()["status"] == "accepted"
    assert second_accept.json()["conversation_id"]
    assert second_accept.json()["session_ends_at"]


def test_secure_agora_call_lifecycle():
    caller_headers, _ = auth_headers("agora-caller@example.com")
    recipient_headers, _ = auth_headers("agora-recipient@example.com")
    outsider_headers, _ = auth_headers("agora-outsider@example.com")
    recipient = client.get("/api/v1/users/me", headers=recipient_headers).json()
    conversation = approved_conversation(caller_headers, recipient_headers, recipient["id"])

    started = client.post(
        "/api/v1/calls",
        headers=caller_headers,
        json={"conversation_id": conversation["id"], "call_type": "video"},
    )
    assert started.status_code == 201, started.text
    call = started.json()
    assert call["status"] == "ringing"
    assert call["rtc"]["token"].startswith("006")
    assert call["rtc"]["userAccount"] == call["callerId"]

    forbidden = client.post(f"/api/v1/calls/{call['id']}/token", headers=outsider_headers)
    assert forbidden.status_code == 404
    before_accept = client.post(f"/api/v1/calls/{call['id']}/token", headers=recipient_headers)
    assert before_accept.status_code == 403

    accepted = client.post(f"/api/v1/calls/{call['id']}/accept", headers=recipient_headers)
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["status"] == "accepted"
    assert accepted.json()["rtc"]["userAccount"] == call["recipientId"]

    ended = client.post(f"/api/v1/calls/{call['id']}/end", headers=caller_headers)
    assert ended.status_code == 200
    assert ended.json()["status"] == "ended"
    expired_token = client.post(f"/api/v1/calls/{call['id']}/token", headers=caller_headers)
    assert expired_token.status_code == 409


def test_availability_and_private_circle_invitation_flow():
    owner_headers, _ = auth_headers("circle-owner@example.com")
    member_headers, _ = auth_headers("circle-member@example.com")
    member = client.get("/api/v1/users/me", headers=member_headers).json()
    availability = client.patch(
        "/api/v1/users/me/availability",
        headers=owner_headers,
        json={"status": "Free to talk", "duration_minutes": 60},
    )
    assert availability.status_code == 200, availability.text
    assert availability.json()["vibe_status"] == "Free to talk"
    circle = client.post(
        "/api/v1/communities",
        headers=owner_headers,
        json={
            "name": "Trusted Test Circle",
            "category": "Private circle",
            "description": "A private circle used for invitation tests.",
            "privacy": "private",
            "kind": "circle",
            "max_members": 8,
        },
    )
    assert circle.status_code == 201, circle.text
    circle_id = circle.json()["id"]
    hidden = client.get("/api/v1/communities", headers=member_headers).json()
    assert circle_id not in {item["id"] for item in hidden}
    invite = client.post(
        f"/api/v1/communities/{circle_id}/invite",
        headers=owner_headers,
        json={"user_id": member["id"]},
    )
    assert invite.status_code == 201, invite.text
    pending = client.get("/api/v1/communities/invitations/me", headers=member_headers).json()
    assert pending[0]["community_id"] == circle_id
    accepted = client.patch(
        f"/api/v1/communities/invitations/{pending[0]['id']}",
        headers=member_headers,
        json={"action": "accept"},
    )
    assert accepted.json()["status"] == "accepted"
    visible = client.get("/api/v1/communities", headers=member_headers).json()
    assert circle_id in {item["id"] for item in visible}


def test_every_user_can_earn_from_paid_chat_calls_gifts_and_communities():
    earner_headers, _ = auth_headers("phase-earner@example.com")
    buyer_headers, _ = auth_headers("phase-buyer@example.com")
    admin_headers, _ = auth_headers("phase-admin@example.com")
    earner = client.get("/api/v1/users/me", headers=earner_headers).json()
    buyer = client.get("/api/v1/users/me", headers=buyer_headers).json()
    admin = client.get("/api/v1/users/me", headers=admin_headers).json()
    with SessionLocal() as db:
        db.get(User, admin["id"]).role = "admin"
        db.commit()

    settings = client.patch("/api/v1/earnings/profile/me", headers=earner_headers, json={
        "availability_status": "available", "chat_price": 40, "audio_price_per_minute": 10,
        "video_price_per_minute": 15, "chat_available": True, "audio_available": True, "video_available": True,
    })
    assert settings.status_code == 405
    pricing = client.get("/api/v1/wallet/pricing", headers=earner_headers).json()
    assert pricing["source"] == "admin_dummy_config"
    assert pricing["chatCoinsPerMinute"] == 2

    coin_package = client.get("/api/v1/wallet/coin-packages", headers=buyer_headers).json()[-1]
    purchased = client.post("/api/v1/wallet/buy-coins", headers=buyer_headers, json={"package_id": coin_package["id"], "purchase_token": "dummy_phase2_coins"})
    assert purchased.status_code == 201, purchased.text
    initial_balance = purchased.json()["purchased_coins"] + purchased.json()["bonus_coins"]

    one_day_plan = client.get("/api/v1/subscriptions/plans", headers=buyer_headers).json()[0]
    subscribed = client.post("/api/v1/subscriptions/purchase", headers=buyer_headers, json={"plan_id": one_day_plan["id"], "purchase_token": "dummy_phase2_plan"})
    assert subscribed.status_code == 201, subscribed.text

    request = client.post("/api/v1/chat/message-requests", headers=buyer_headers, json={"recipient_id": earner["id"], "introduction": "I would like a private advice conversation."})
    assert request.status_code == 201, request.text
    assert request.json()["chatPricePerMinute"] == 2
    assert request.json()["reservedMinutes"] == 10
    assert request.json()["chatPrice"] == 20
    held_wallet = client.get("/api/v1/wallet", headers=buyer_headers).json()
    assert held_wallet["held_coins"] == 20
    accepted = client.patch(f"/api/v1/chat/message-requests/{request.json()['id']}", headers=earner_headers, json={"action": "accept"})
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["paid"] is True
    settled_wallet = client.get("/api/v1/wallet", headers=buyer_headers).json()
    assert settled_wallet["held_coins"] == 0
    assert settled_wallet["purchased_coins"] + settled_wallet["bonus_coins"] == initial_balance - 20

    chat_rating = client.post("/api/v1/ratings", headers=buyer_headers, json={
        "session_id": accepted.json()["conversationId"], "overall_rating": 4,
        "conversation_quality": 4, "behaviour": 5, "helpfulness": 4,
        "media_quality": 4, "review": "A good paid chat.",
    })
    assert chat_rating.status_code == 201, chat_rating.text

    private_post = client.post("/api/v1/feed/posts", headers=earner_headers, json={
        "type": "text", "body": "This is paid private post content.", "visibility": "private",
    })
    assert private_post.status_code == 201, private_post.text
    locked_post = next(item for item in client.get("/api/v1/feed/posts", headers=buyer_headers).json() if item["id"] == private_post.json()["id"])
    assert locked_post["locked"] is True
    assert locked_post["coin_price"] == 15
    assert "paid private post content" not in locked_post["body"]
    unlocked_post = client.post(f"/api/v1/feed/posts/{private_post.json()['id']}/unlock", headers=buyer_headers)
    assert unlocked_post.status_code == 200, unlocked_post.text
    assert unlocked_post.json()["locked"] is False
    assert unlocked_post.json()["body"] == "This is paid private post content."

    before_call = client.get("/api/v1/wallet", headers=buyer_headers).json()
    started = client.post("/api/v1/calls", headers=buyer_headers, json={"recipient_id": earner["id"], "call_type": "audio", "duration_minutes": 5})
    assert started.status_code == 201, started.text
    accepted_call = client.post(f"/api/v1/calls/{started.json()['id']}/accept", headers=earner_headers)
    assert accepted_call.status_code == 200, accepted_call.text
    assert accepted_call.json()["heldCoins"] == 25
    assert accepted_call.json()["heldCreditMinutes"] == 0
    assert client.post(f"/api/v1/calls/{started.json()['id']}/join", headers=buyer_headers).status_code == 200
    joined_call = client.post(f"/api/v1/calls/{started.json()['id']}/join", headers=earner_headers)
    assert joined_call.status_code == 200, joined_call.text
    assert joined_call.json()["startedAt"]
    ended = client.post(f"/api/v1/calls/{started.json()['id']}/end", headers=buyer_headers)
    assert ended.status_code == 200, ended.text
    assert ended.json()["usedCreditMinutes"] == 0
    assert ended.json()["chargedCoins"] == 5
    after_call = client.get("/api/v1/wallet", headers=buyer_headers).json()
    assert after_call["purchased_coins"] + after_call["bonus_coins"] == before_call["purchased_coins"] + before_call["bonus_coins"] - 5

    rating = client.post("/api/v1/ratings", headers=buyer_headers, json={
        "session_id": started.json()["id"], "overall_rating": 5, "conversation_quality": 5,
        "behaviour": 5, "helpfulness": 5, "media_quality": 4, "review": "Helpful and respectful.",
    })
    assert rating.status_code == 201, rating.text
    reviews = client.get(f"/api/v1/users/{earner['id']}/reviews", headers=buyer_headers)
    assert reviews.status_code == 200
    assert reviews.json()[0]["overall_rating"] == 5

    with SessionLocal() as db:
        profile = db.query(CreatorProfile).filter(CreatorProfile.user_id == earner["id"]).one()
        profile.rating_total = 15
        profile.rating_count = 3
        profile.completed_sessions = 3
        db.commit()
    recommendations = client.get("/api/v1/discovery/recommended-people", headers=buyer_headers).json()
    recommended_earner = next(item for item in recommendations if item["id"] == earner["id"])
    assert recommended_earner["performance_tier"] == "top_performer"
    assert recommended_earner["performance_rating"] == 5

    gift = client.get("/api/v1/gifts", headers=buyer_headers).json()[0]
    gifted = client.post("/api/v1/gifts/send", headers=buyer_headers, json={"gift_id": gift["id"], "recipient_id": earner["id"], "target_type": "user_profile", "target_id": earner["id"]})
    assert gifted.status_code == 201, gifted.text

    community = client.post("/api/v1/communities", headers=earner_headers, json={
        "name": "Phase Premium Circle", "category": "Advice", "description": "A premium space for thoughtful advice.",
        "privacy": "private", "premium_price": 999, "rules": ["Be respectful"],
    })
    assert community.status_code == 201, community.text
    assert community.json()["premium_price"] == 999
    visible_private = client.get("/api/v1/communities", headers=buyer_headers).json()
    assert community.json()["id"] in {item["id"] for item in visible_private}
    locked_feed = client.get("/api/v1/feed/posts", headers=buyer_headers, params={"community_id": community.json()["id"]})
    assert locked_feed.status_code == 402
    joined = client.post(f"/api/v1/communities/{community.json()['id']}/join", headers=buyer_headers)
    assert joined.status_code == 200, joined.text

    with SessionLocal() as db:
        for transaction in db.query(CreatorTransaction).filter(CreatorTransaction.creator_id == earner["id"]).all():
            transaction.settles_at = datetime.now(UTC) - timedelta(minutes=1)
        db.commit()
    dashboard = client.get("/api/v1/earnings/dashboard", headers=earner_headers)
    assert dashboard.status_code == 200, dashboard.text
    assert dashboard.json()["availableBalance"] > 0
    wallet_dashboard = client.get("/api/v1/wallet/dashboard", headers=earner_headers, params={"period": "30d"})
    assert wallet_dashboard.status_code == 200, wallet_dashboard.text
    assert wallet_dashboard.json()["totalEarned"] > 0
    assert wallet_dashboard.json()["chart"]
    assert wallet_dashboard.json()["history"]
    withdrawal = client.post("/api/v1/earnings/withdrawals", headers=earner_headers, json={"amount": 10, "payout_account_reference": "test-payout-account"})
    assert withdrawal.status_code == 201, withdrawal.text
    withdrawal_id = withdrawal.json()["id"]
    for status in ["under_review", "approved", "processing"]:
        progressed = client.patch(f"/api/v1/admin/withdrawals/{withdrawal_id}/review", headers=admin_headers, json={"status": status, "reason": "Dummy payout processing"})
        assert progressed.status_code == 200, progressed.text
    paid = client.patch(f"/api/v1/admin/withdrawals/{withdrawal_id}/review", headers=admin_headers, json={"status": "paid", "reason": "Dummy payout completed"})
    assert paid.status_code == 200, paid.text


def test_post_tipping_boosting_and_bounty():
    author_headers, _ = auth_headers("tip-author@example.com")
    buyer_headers, _ = auth_headers("tip-buyer@example.com")

    # Buy coins for buyer
    package = client.get("/api/v1/wallet/coin-packages", headers=buyer_headers).json()[0]
    purchased = client.post(
        "/api/v1/wallet/buy-coins",
        headers=buyer_headers,
        json={"package_id": package["id"], "purchase_token": "dummy_tip_coins"},
    )
    assert purchased.status_code == 201

    # Author creates a public post
    post = client.post(
        "/api/v1/feed/posts",
        headers=author_headers,
        json={"type": "text", "body": "A normal post to test tipping and boosting", "visibility": "public"},
    )
    assert post.status_code == 201
    post_id = post.json()["id"]

    # 1. Post Tipping
    tip = client.post(
        f"/api/v1/feed/posts/{post_id}/tip",
        headers=buyer_headers,
        json={"amount": 25, "message": "Super tip!"},
    )
    assert tip.status_code == 200, tip.text
    assert tip.json()["tip_count"] == 1
    assert tip.json()["tip_total"] == 25

    # Check tipping history
    tips = client.get(f"/api/v1/feed/posts/{post_id}/tips", headers=buyer_headers)
    assert tips.status_code == 200
    assert len(tips.json()) == 1
    assert tips.json()[0]["amount"] == 25
    assert tips.json()[0]["message"] == "Super tip!"

    # 2. Post Boosting
    # Buy coins for author first to afford boost (50 coins)
    author_purchased = client.post(
        "/api/v1/wallet/buy-coins",
        headers=author_headers,
        json={"package_id": package["id"], "purchase_token": "dummy_boost_coins"},
    )
    assert author_purchased.status_code == 201

    boost = client.post(
        f"/api/v1/feed/posts/{post_id}/boost",
        headers=author_headers,
    )
    assert boost.status_code == 200, boost.text
    assert boost.json()["is_boosted"] is True
    assert boost.json()["boost_cost"] == 50

    # 3. Post Bounty (Ask & Earn)
    # Author creates a question post with bounty
    bounty_post = client.post(
        "/api/v1/feed/posts",
        headers=author_headers,
        json={"type": "question", "body": "Who knows Python?", "visibility": "public", "bounty_amount": 50},
    )
    assert bounty_post.status_code == 201, bounty_post.text
    bounty_post_id = bounty_post.json()["id"]
    assert bounty_post.json()["bounty_amount"] == 50
    assert bounty_post.json()["bounty_status"] == "open"

    # Buyer comments on the question
    comment = client.post(
        f"/api/v1/feed/posts/{bounty_post_id}/comments",
        headers=buyer_headers,
        json={"body": "I know Python very well!"},
    )
    assert comment.status_code == 201, comment.text
    comment_id = comment.json()["id"]

    # Author awards the bounty to the buyer
    award = client.post(
        f"/api/v1/feed/posts/{bounty_post_id}/award-bounty",
        headers=author_headers,
        json={"comment_id": comment_id},
    )
    assert award.status_code == 200, award.text
    assert award.json()["status"] == "awarded"
    assert award.json()["bounty_winner_comment_id"] == comment_id

    # Check bounty status
    bounty_status = client.get(f"/api/v1/feed/posts/{bounty_post_id}/bounty", headers=buyer_headers)
    assert bounty_status.status_code == 200
    assert bounty_status.json()["bountyStatus"] == "awarded"
    assert bounty_status.json()["winner"]["comment_id"] == comment_id

