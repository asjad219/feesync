allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val subproject = this
        // Safe access to Android extension to force NDK and ABI settings for all modules (including plugins)
        if (subproject.extensions.findByName("android") != null) {
            val android = subproject.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.ndkVersion = "28.2.13676358"
                android.defaultConfig {
                    ndk {
                        abiFilters.clear()
                        abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
                    }
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
