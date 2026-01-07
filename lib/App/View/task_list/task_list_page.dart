// Importaciones necesarias para el funcionamiento de la página
import 'package:ejemplo_00/App/View/components/texto.dart';
import 'package:ejemplo_00/App/model/task.dart';
import 'package:ejemplo_00/App/repository/task_repository.dart';
import 'package:flutter/material.dart';

// Widget principal de la página de lista de tareas
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

// Estado de TaskListPage - aquí se maneja toda la lógica
class _TaskListPageState extends State<TaskListPage> {
  // Instancia del repositorio para acceder a las operaciones de tareas
  final TaskRepository repository = TaskRepository();

  // Lista que contiene todas las tareas
  List<Task> tasks = [];

  // Variable para indicar si estamos cargando las tareas
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final loadedTasks = await repository.getTasks();

      if (mounted) {
        setState(() {
          tasks = loadedTasks;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Error al cargar las tareas');
      }
    }
  }

  Future<void> _toggleDone(int index) async {
    try {
      setState(() {
        tasks[index].done = !tasks[index].done;
      });

      await repository.saveTasks(tasks);

      if (mounted) {
        _showSuccessSnackBar(
            tasks[index].done
                ? '¡Tarea completada! 🎉'
                : 'Tarea marcada como pendiente'
        );
      }
    } catch (e) {
      setState(() {
        tasks[index].done = !tasks[index].done;
      });
      _showErrorSnackBar('Error al actualizar la tarea');
    }
  }

  Future<void> _deleteTask(int index) async {
    final deletedTask = tasks[index];

    setState(() {
      tasks.removeAt(index);
    });

    try {
      await repository.saveTasks(tasks);

      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();

        final snackBar = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarea eliminada'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'DESHACER',
              onPressed: () async {
                setState(() {
                  tasks.insert(index, deletedTask);
                });
                await repository.saveTasks(tasks);
              },
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            snackBar.close();
          }
        });
      }
    } catch (e) {
      setState(() {
        tasks.insert(index, deletedTask);
      });
      _showErrorSnackBar('Error al eliminar la tarea');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Getter para calcular el número de tareas completadas
  int get completedTasksCount => tasks.where((task) => task.done).length;

  // Getter para calcular el número de tareas pendientes
  int get pendingTasksCount => tasks.length - completedTasksCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar minimalista - solo con la flecha de retroceso
      appBar: AppBar(
        backgroundColor: const Color(0xFF40B7AD), // Mismo color que el header
        elevation: 0, // Sin sombra para que parezca un solo bloque
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
      ),
      // Cuerpo principal de la página
      body: Column(
        children: [
          // Header con imagen y estadísticas (como estaba antes)
          _Header(
            totalTasks: tasks.length,
            completedTasks: completedTasksCount,
          ),

          // Lista de tareas
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                ? _EmptyState()
                : RefreshIndicator(
              onRefresh: _loadTask,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final task = tasks[index];

                  return Dismissible(
                    key: ValueKey('${task.title}_$index'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      ScaffoldMessenger.of(context).clearSnackBars();

                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: Text(
                              '¿Estás seguro de eliminar "${task.title}"?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      return result ?? false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white, size: 32),
                          SizedBox(height: 4),
                          Text(
                            'Eliminar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) => _deleteTask(index),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: CheckboxListTile(
                        value: task.done,
                        onChanged: (_) => _toggleDone(index),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.done
                                ? Colors.grey
                                : null,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: task.done
                            ? const Text(
                          '✓ Completada',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        )
                            : null,
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Botón flotante
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTaskModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }

  Future<void> _showNewTaskModal(BuildContext context) async {
    final task = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewTaskModal(),
    );

    if (task != null) {
      try {
        await repository.addTask(task);
        await _loadTask();
        if (mounted) {
          _showSuccessSnackBar('Tarea agregada exitosamente');
        }
      } catch (e) {
        _showErrorSnackBar('Error al agregar la tarea');
      }
    }
  }
}

// Modal para crear nueva tarea
class _NewTaskModal extends StatefulWidget {
  const _NewTaskModal();

  @override
  State<_NewTaskModal> createState() => _NewTaskModalState();
}

class _NewTaskModalState extends State<_NewTaskModal> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
        color: Colors.white,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Texto(mitexto: 'Nueva tarea'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLength: 100,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Ej: Comprar leche, Hacer ejercicio...',
                labelText: 'Descripción',
                prefixIcon: const Icon(Icons.task_alt),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                if (value.trim().length < 3) {
                  return 'La descripción debe tener al menos 3 caracteres';
                }
                return null;
              },
              onFieldSubmitted: (_) => _createTask(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text(
                'Guardar tarea',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _createTask() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isCreating = true;
      });

      final task = Task(_controller.text.trim());
      Navigator.of(context).pop(task);
    }
  }
}

// Estado vacío
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera tarea\npresionando el botón',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// Header con imagen y estadísticas (versión original)
class _Header extends StatelessWidget {
  const _Header({
    required this.totalTasks,
    required this.completedTasks,
  });

  final int totalTasks;
  final int completedTasks;

  @override
  Widget build(BuildContext context) {
    // Calculamos el porcentaje de completado
    final percentage = totalTasks > 0
        ? (completedTasks / totalTasks * 100).toStringAsFixed(0)
        : '0';

    return Container(
      color: const Color(0xFF40B7AD), // Color turquesa - mismo que el AppBar
      child: Stack(
        children: [
          // Contenido centrado
          Center(
            child: Column(
              children: [
                // Título
                const textTask(
                  mitexto: 'Completa tus tareas',
                  micolor: Colors.white,
                ),
                // Mostrar estadísticas solo si hay tareas
                if (totalTasks > 0) ...[
                  const SizedBox(height: 16),
                  // Badge con estadísticas (recuadro verde)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completedTasks de $totalTasks completadas ($percentage%)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}