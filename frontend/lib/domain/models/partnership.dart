/// Canal de venda ativo disponibilizado pela API.
class Partnership {
  const Partnership({
    required this.id,
    required this.name,
    required this.channel,
  });

  final String id;
  final String name;
  final String channel;

  factory Partnership.fromJson(Map<String, dynamic> json) => Partnership(
        id: json['id'] as String,
        name: json['name'] as String,
        channel: json['channel'] as String,
      );
}
