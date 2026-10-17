allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Kotlin incremental compilation stores source paths relative to the root
// project directory (android\). Flutter plugin subprojects live in the pub
// cache, which may be on a different Windows drive. When it is, Kotlin's
// RelocatableFileToPathConverter throws "this and base files have different
// roots" (KT-63983) and the build fails. Turn IC off only for subprojects
// outside the project root (the pub-cache plugins); the :app module, whose
// sources are inside android\, stays incremental.
subprojects {
    if (!projectDir.canonicalPath.startsWith(rootDir.canonicalPath)) {
        extra["kotlin.incremental"] = "false"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
