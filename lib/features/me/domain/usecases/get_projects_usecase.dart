import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository repository;

  const GetProjectsUseCase(this.repository);

  Future<List<ProjectEntity>> call() {
    return repository.getProjects();
  }
}
