plugins {
    kotlin("multiplatform") version "2.0.21-KBA-003"
    id("com.google.devtools.ksp") version "2.0.21-1.0.28" apply false
    id("com.tencent.kuiklybase.knoi.plugin") version "0.0.4"
}

kotlin {
    ohosArm64 {
        binaries.sharedLib {
            baseName = "kn"
        }
        binaries.all {
            freeCompilerArgs += "-opt=true"
            freeCompilerArgs += "-Xadd-light-debug=enable"
            freeCompilerArgs += "-Xcontext-receivers"
            freeCompilerArgs += "-memory-model=experimental"
            freeCompilerArgs += "-Xbinary=gc=pmcs"
            freeCompilerArgs += "-Xbinary=sourceInfoType=libbacktrace"
        }
    }

    sourceSets {
        val ohosArm64Main by getting {
            kotlin.srcDir("../common/src/commonMain/kotlin")
        }
    }
}

knoi {
    tsGenDir = project.layout.buildDirectory.dir("ts-api").get().asFile.absolutePath
    ignoreTypeAssert = false
}

val harmonyEntryDir = rootProject.layout.projectDirectory.dir("../harmonyApp/entry")
val harmonySourceLibDir = harmonyEntryDir.dir("src/main/libs/arm64-v8a")
val harmonyPackagedLibDir = harmonyEntryDir.dir("libs/arm64-v8a")
val harmonyKnoiDir = harmonyEntryDir.dir("src/main/ets/knoi")

tasks.register<Copy>("copyLibKnToHarmony") {
    dependsOn("linkDebugSharedOhosArm64")
    from(layout.buildDirectory.file("bin/ohosArm64/debugShared/libkn.so"))
    into(harmonySourceLibDir)
}

tasks.register<Copy>("copyPackagedLibKnToHarmony") {
    dependsOn("linkDebugSharedOhosArm64")
    from(layout.buildDirectory.file("bin/ohosArm64/debugShared/libkn.so"))
    into(harmonyPackagedLibDir)
}

tasks.register<Copy>("copyKnoiTsApiToHarmony") {
    dependsOn("kspKotlinOhosArm64")
    from(layout.buildDirectory.dir("ts-api"))
    into(harmonyKnoiDir)
}

tasks.named("ohosArm64Binaries") {
    finalizedBy("copyLibKnToHarmony", "copyPackagedLibKnToHarmony", "copyKnoiTsApiToHarmony")
}
