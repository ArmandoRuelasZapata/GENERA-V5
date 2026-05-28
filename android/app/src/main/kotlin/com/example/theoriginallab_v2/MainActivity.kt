package com.example.theoriginallab_v2

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.os.Bundle
import java.io.File

class MainActivity: FlutterActivity() {
    private val securityChannelName = "com.originallab/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Capturas permitidas temporalmente en todas las variantes.
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSimulator" -> result.success(isEmulator())
                    "isTampered" -> result.success(isTampered())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val device = Build.DEVICE.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()

        val buildHeuristic = fingerprint.startsWith("generic")
            || fingerprint.contains("vbox")
            || fingerprint.contains("test-keys")
            || model.contains("emulator")
            || model.contains("android sdk built for x86")
            || manufacturer.contains("genymotion")
            || (brand.startsWith("generic") && device.startsWith("generic"))
            || product.contains("sdk")
            || hardware.contains("goldfish")
            || hardware.contains("ranchu")

        if (buildHeuristic) {
            return true
        }

        val emulatorArtifacts = listOf(
            "/dev/socket/qemud",
            "/dev/qemu_pipe",
            "/system/lib/libc_malloc_debug_qemu.so",
            "/sys/qemu_trace"
        )
        return emulatorArtifacts.any { File(it).exists() }
    }

    private fun isTampered(): Boolean {
        if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            return true
        }

        // Detect debugger attach
        if (android.os.Debug.isDebuggerConnected() || android.os.Debug.waitingForDebugger()) {
            return true
        }

        val fridaArtifacts = listOf(
            "/data/local/tmp/frida-server",
            "/data/local/tmp/re.frida.server",
            "/system/bin/frida-server",
            "/system/xbin/frida-server"
        )
        if (fridaArtifacts.any { File(it).exists() }) {
            return true
        }

        return try {
            val status = File("/proc/self/status").readText()
            val tracerLine = status
                .lineSequence()
                .firstOrNull { it.startsWith("TracerPid:") }
                ?.substringAfter("TracerPid:")
                ?.trim()
            val tracerPid = tracerLine?.toIntOrNull() ?: 0
            tracerPid > 0
        } catch (_: Exception) {
            false
        }
    }
}
