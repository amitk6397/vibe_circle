class Community {
  final String id;
  final String name;
  final String description;
  final String? coverUrl;
  final String? avatarUrl;
  final String? logoUrl;
  final bool isPrivate;
  final int memberCount;
  final int members;
  final String category;
  final String themeColor;
  final String color;
  final List<String> tags;
  final bool isJoined;
  final bool joined;
  final bool isOwner;
  final bool joinPending;
  final String kind;
  final String privacy;
  final int maxMembers;
  final List<String> rules;

  Community({
    required this.id,
    required this.name,
    required this.description,
    this.coverUrl,
    this.avatarUrl,
    this.logoUrl,
    required this.isPrivate,
    required this.memberCount,
    required this.members,
    required this.category,
    required this.themeColor,
    required this.color,
    required this.tags,
    this.isJoined = false,
    this.joined = false,
    this.isOwner = false,
    this.joinPending = false,
    this.kind = 'community',
    this.privacy = 'public',
    this.maxMembers = 50,
    this.rules = const [],
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    final logo = json['logo_url'] ?? json['avatar_url'];
    final count = json['members'] ?? json['member_count'] ?? 0;
    final priv = json['privacy'] ?? (json['is_private'] == true ? 'private' : 'public');
    final c = json['color'] ?? json['theme_color'] ?? '#7C3AED';
    final isJ = json['joined'] ?? json['is_joined'] ?? false;
    final isO = json['is_owner'] ?? json['isOwner'] ?? false;
    final joinP = json['join_pending'] ?? json['joinPending'] ?? false;

    return Community(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['cover_url'],
      avatarUrl: logo,
      logoUrl: logo,
      isPrivate: priv == 'private',
      memberCount: count,
      members: count,
      category: json['category'] ?? 'General',
      themeColor: c,
      color: c,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isJoined: isJ,
      joined: isJ,
      isOwner: isO,
      joinPending: joinP,
      kind: json['kind'] ?? 'community',
      privacy: priv,
      maxMembers: json['max_members'] ?? json['maxMembers'] ?? 50,
      rules: (json['rules'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_url': coverUrl,
      'avatar_url': avatarUrl,
      'logo_url': logoUrl,
      'is_private': isPrivate,
      'member_count': memberCount,
      'members': members,
      'category': category,
      'theme_color': themeColor,
      'color': color,
      'tags': tags,
      'is_joined': isJoined,
      'joined': joined,
      'is_owner': isOwner,
      'join_pending': joinPending,
      'kind': kind,
      'privacy': privacy,
      'max_members': maxMembers,
      'rules': rules,
    };
  }
}

