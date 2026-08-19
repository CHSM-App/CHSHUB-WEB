buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Google Services Gradle plugin (required for Firebase)
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.android.tools.build:gradle:7.4.2") // <-- Make sure you include this too!
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional custom build directory (only if you're intentionally overriding it)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
