allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.lifecycle:lifecycle-runtime:2.7.0")
            force("androidx.lifecycle:lifecycle-viewmodel:2.7.0")
            force("androidx.activity:activity:1.8.2")
            force("androidx.fragment:fragment:1.6.2")
            force("androidx.multidex:multidex:2.0.1")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
