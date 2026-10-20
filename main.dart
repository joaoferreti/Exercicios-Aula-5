import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class Post {
  final int? id;
  final int userId;
  final String title;
  final String body;

  Post({this.id, required this.userId, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        userId: json['userId'],
        title: json['title'] ?? '',
        body: json['body'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };
}

class PostService {
  static const _baseUrl = 'https://jsonplaceholder.typicode.com/posts';
  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  Future<List<Post>> getPosts() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Post.fromJson(e)).toList();
    }
    throw Exception('Falha ao carregar posts (${response.statusCode})');
  }

  Future<Post> getPost(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    }
    throw Exception('Falha ao carregar post $id (${response.statusCode})');
  }

  Future<Post> createPost(Post post) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode(post.toJson()),
    );
    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    }
    throw Exception('Falha ao criar post (${response.statusCode})');
  }

  Future<Post> updatePost(Post post) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/${post.id}'),
      headers: _headers,
      body: jsonEncode(post.toJson()),
    );
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    }
    throw Exception('Falha ao atualizar post ${post.id} (${response.statusCode})');
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir post $id (${response.statusCode})');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSONPlaceholder CRUD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _service = PostService();
  final _idController = TextEditingController();
  final _userIdController = TextEditingController(text: '1');
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  List<Post> _posts = [];
  String _status = '';
  bool _loading = false;

  @override
  void dispose() {
    _idController.dispose();
    _userIdController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  int _requireId() {
    final id = int.tryParse(_idController.text);
    if (id == null) throw Exception('Informe um ID válido');
    return id;
  }

  Post _formPost({int? id}) => Post(
        id: id,
        userId: int.tryParse(_userIdController.text) ?? 1,
        title: _titleController.text,
        body: _bodyController.text,
      );

  void _fill(Post post) {
    _idController.text = post.id?.toString() ?? '';
    _userIdController.text = post.userId.toString();
    _titleController.text = post.title;
    _bodyController.text = post.body;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _getList() => _run(() async {
        final posts = await _service.getPosts();
        setState(() {
          _posts = posts;
          _status = 'GET (lista): ${posts.length} posts carregados';
        });
      });

  Future<void> _getOne() => _run(() async {
        final id = _requireId();
        final post = await _service.getPost(id);
        setState(() {
          _fill(post);
          _posts = [post];
          _status = 'GET: post $id carregado';
        });
      });

  Future<void> _create() => _run(() async {
        final created = await _service.createPost(_formPost());
        setState(() {
          _fill(created);
          _posts = [created];
          _status = 'POST: post criado com id ${created.id}';
        });
      });

  Future<void> _update() => _run(() async {
        final id = _requireId();
        final updated = await _service.updatePost(_formPost(id: id));
        setState(() {
          _posts = [updated];
          _status = 'PUT: post $id atualizado';
        });
      });

  Future<void> _delete() => _run(() async {
        final id = _requireId();
        await _service.deletePost(id);
        setState(() {
          _posts.removeWhere((p) => p.id == id);
          _status = 'DELETE: post $id excluído';
        });
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSONPlaceholder - Posts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'User ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Conteúdo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _loading ? null : _getOne, child: const Text('GET')),
                FilledButton(onPressed: _loading ? null : _getList, child: const Text('GET Lista')),
                FilledButton(onPressed: _loading ? null : _create, child: const Text('POST')),
                FilledButton(onPressed: _loading ? null : _update, child: const Text('PUT')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _loading ? null : _delete,
                  child: const Text('DELETE'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _posts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${post.id ?? '-'}')),
                    title: Text(post.title),
                    subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => setState(() => _fill(post)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
