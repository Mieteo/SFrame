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

    // Một số package cũ (vd: gallery_saver 2.3.2) không khai báo `namespace` —
    // điều mà AGP 8+ bắt buộc. Patch vá tại đây để build thành công mà không
    // cần fork hoặc đổi package.
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                val getNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
                val currentNamespace = getNamespace?.invoke(androidExt) as String?
                if (currentNamespace.isNullOrBlank()) {
                    val setNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "setNamespace" }
                    setNamespace?.invoke(androidExt, "com.example.${project.name.replace('-', '_')}")
                }
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
