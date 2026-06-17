import '../models/ticket_model.dart';
import 'api_service.dart';

/// Camada de dados: faz as chamadas HTTP aos endpoints de tickets.
class TicketService {
  final ApiService _api = ApiService();

  // READ — GET /api/tickets
  Future<List<TicketModel>> fetchAll({String? status, String? priority}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    final response = await _api.dio.get('/tickets', queryParameters: params);
    final List data = response.data['data'] as List;
    return data.map((e) => TicketModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  // READ ONE — GET /api/tickets/:id
  Future<TicketModel> fetchById(String id) async {
    final response = await _api.dio.get('/tickets/$id');
    return TicketModel.fromMap(response.data['data'] as Map<String, dynamic>);
  }

  // CREATE — POST /api/tickets
  Future<TicketModel> create({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
    String? activityId,
    String? department,
    String? aiSummary,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'priority': priority,
    };
    if (categoryId != null) body['categoryId'] = categoryId;
    if (activityId != null) body['activityId'] = activityId;
    if (department != null) body['department'] = department;
    if (aiSummary != null) body['aiSummary'] = aiSummary;

    final response = await _api.dio.post('/tickets', data: body);
    return TicketModel.fromMap(response.data['data'] as Map<String, dynamic>);
  }

  // UPDATE — PUT /api/tickets/:id
  Future<TicketModel> update(String id, {
    String? title,
    String? description,
    String? status,
    String? priority,
    String? aiSummary,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;
    if (priority != null) body['priority'] = priority;
    if (aiSummary != null) body['aiSummary'] = aiSummary;

    final response = await _api.dio.put('/tickets/$id', data: body);
    return TicketModel.fromMap(response.data['data'] as Map<String, dynamic>);
  }

  // DELETE — DELETE /api/tickets/:id
  Future<void> delete(String id) async {
    await _api.dio.delete('/tickets/$id');
  }

  // ASSIGN — PUT /api/tickets/:id/assign
  Future<TicketModel> assignToMe(String id) async {
    final response = await _api.dio.put('/tickets/$id/assign');
    return TicketModel.fromMap(response.data['data'] as Map<String, dynamic>);
  }
}
