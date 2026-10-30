abstract class ProjectRepo {
  Future<void> addProject(
    String userId,
    String projectType,
    String projectName,
    String companyId,
    String companyName,
  );
}
