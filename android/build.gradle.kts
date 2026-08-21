import com.android.build.gradle.BaseExtension

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

    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

allprojects {
    fun configure() {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? BaseExtension
            android?.let {
                it.compileSdkVersion(36)
                it.buildToolsVersion("36.0.0")
            }
        }
    }
    if (project.state.executed) configure() else project.afterEvaluate { configure() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
