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
// Some plugins still compile against an older Android API (file_picker 8:
// android-34), but plugins they depend on now require 36, which fails
// checkReleaseAarMetadata (docs-and-plan#325). Raise those to 36. This only
// changes the API they compile against, not targetSdk or minSdk.
// Registered before the evaluationDependsOn block below evaluates :app.
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.let { android ->
                if ((android.compileSdk ?: 0) < 36) android.compileSdk = 36
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
