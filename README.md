# App Seguridad Ciudadana (Muni Locumba)

Este es el repositorio de la aplicación móvil de Seguridad Ciudadana para la Municipalidad de Locumba, desarrollada con **Flutter**.

---

## 🛠️ Requisitos Previos y Configuración del Entorno

Sigue estos pasos detallados para configurar tu entorno de desarrollo en Windows:

### 1. Descarga e Instalación de Android Studio
Android Studio es el entorno oficial recomendado. Aunque puedes escribir tu código en cualquier editor (como VS Code), Android Studio es necesario para administrar el SDK de Android, las herramientas de compilación y los controladores de tus dispositivos.

1. **Descargar el Instalador:**
   * Ve al sitio oficial de [Android Studio](https://developer.android.com/studio) y descarga la versión estable más reciente para Windows.
2. **Ejecutar el Setup Wizard (Asistente de Configuración):**
   * Ejecuta el instalador descargado y sigue las instrucciones en pantalla (puedes dejar todas las opciones por defecto).
   * Al abrir Android Studio por primera vez, selecciona **Do not import settings** en la ventana emergente y luego avanza en el Asistente de Configuración.
   * Elige la instalación de tipo **Standard**. Esto descargará automáticamente en tu perfil de usuario:
     * **Android SDK** (Las librerías del sistema Android necesarias para compilar la aplicación).
     * **Android SDK Platform-Tools** (Herramientas de bajo nivel como `adb`, que permiten que tu PC reconozca tu celular físico).
     * **Java OpenJDK** integrado (versión de Java compatible con Gradle y Flutter).
3. **Instalar las Herramientas de Línea de Comandos (SDK Command-line Tools) [MUY IMPORTANTE]:**
   * Flutter necesita herramientas de terminal adicionales para interactuar con Android.
   * En la pantalla de bienvenida de Android Studio, haz clic en **More Actions** (icono de tres puntos verticales o botón en la parte superior derecha) y selecciona **SDK Manager**.
     *(Si ya tienes un proyecto abierto, puedes ir a **Tools > SDK Manager** o **File > Settings > Appearance & Behavior > System Settings > Android SDK**).*
   * En la ventana que aparece, selecciona la pestaña **SDK Tools** (al lado de *SDK Platforms*).
   * Busca en la lista la opción **Android SDK Command-line Tools (latest)** y **marca su casilla**.
   * Haz clic en **Apply** (Aplicar) en la parte inferior, confirma la descarga en la ventana emergente y espera a que finalice. Haz clic en **Finish** y luego en **OK** para cerrar el manager.


### 2. Instalación de Flutter SDK
1. **Descargar el SDK:**
   * Entra a la [Página Oficial de Descargas de Flutter](https://docs.flutter.dev/get-started/install).
   * Haz clic en **Windows** y luego selecciona la plataforma a la que apuntas (para este proyecto, haz clic en **Mobile**).
   * Desplázate hacia abajo hasta la sección **Get the Flutter SDK** y haz clic en el botón azul para descargar el archivo comprimido `.zip` (por ejemplo: `flutter_windows_3.24.6-stable.zip`).
   * *Alternativa rápida:* También puedes ir directamente al [Archivo de versiones de Flutter para Windows](https://docs.flutter.dev/release/archive?tab=windows) y descargar la versión estable (`stable`) recomendada en formato `.zip`.
2. **Extraer:** Crea una carpeta en tu disco local `C:\` llamada `src` (ej. `C:\src`) y descomprime allí el contenido del archivo zip. La carpeta `flutter` debe quedar dentro de `src`, teniendo como ruta final `C:\src\flutter`.
   > [!WARNING]
   > Evita a toda costa instalar o extraer Flutter en rutas protegidas por el sistema (como `C:\Program Files\` o `C:\Archivos de programa\`), ya que esto causará errores por falta de permisos de escritura al compilar.
3. **Agregar al PATH:**
   * Busca **"Editar las variables de entorno del sistema"** en el menú Inicio de Windows.
   * Haz clic en el botón **Variables de entorno...**.
   * En la sección superior "Variables de usuario", selecciona y edita la variable **`Path`** (o `PATH`).
   * Añade una nueva línea con la ruta: `C:\src\flutter\bin`.
   * Haz clic en Aceptar en todas las ventanas y **reinicia tu consola** (PowerShell o CMD).

### 3. Configuración en Android Studio y Licencias
1. **Plugins:** Abre Android Studio, ve a **Plugins** en el menú lateral, busca **"Flutter"** e instálalo (esto instalará automáticamente también el plugin de **Dart**). Reinicia Android Studio al terminar.
2. **Licencias de Android:** Abre una consola y ejecuta el siguiente comando para aceptar las licencias de Google:
   ```powershell
   flutter doctor --android-licenses
   ```
   Presiona la tecla `y` y luego `Enter` a cada una de las licencias hasta finalizar.
3. **Verificación:** Ejecuta el siguiente comando para comprobar que tu entorno esté listo:
   ```powershell
   flutter doctor
   ```

### 4. Habilitar Modo Programador en Windows (Obligatorio)
Para que Flutter pueda crear los enlaces simbólicos (symlinks) necesarios para compilar plugins en Windows, debes activar el Modo Programador:
1. Abre la configuración ejecutando en tu consola:
   ```powershell
   start ms-settings:developers
   ```
2. Activa el interruptor de **Modo de programador** (Developer Mode) y acepta la advertencia.

---

## 📱 Conectar tu Dispositivo Físico

Es recomendable probar en un celular físico para no saturar los recursos de tu PC:
1. En tu celular, ve a **Ajustes > Acerca del teléfono**.
2. Presiona 7 veces seguidas el **Número de compilación** (o Versión de tu capa de personalización como MIUI/HyperOS/etc.) para activar las *Opciones de desarrollador*.
3. Entra a las Opciones de desarrollador (en Ajustes Adicionales o Sistema) y activa la **Depuración por USB**.
4. Conecta tu celular a la PC mediante cable USB, desbloquea la pantalla de tu móvil y acepta el aviso de confirmación permitiendo siempre la conexión desde esta computadora.
5. Verifica que tu dispositivo sea reconocido en la consola con:
   ```powershell
   flutter devices
   ```

---

## ⚙️ Configuración del Servidor API en la App

La aplicación móvil se conecta al backend por HTTP. Puedes cambiar el servidor al que apunta de dos maneras:

### A. Cambiar la URL por defecto en el Código (Para compilaciones estables)
Abre el archivo [app_config.dart](file:///c:/Users/denni/Documents/MuniLocumba/appMuni/lib/core/config/app_config.dart) y modifica la constante:
```dart
static const String defaultServerUrl = 'http://192.168.1.100:8000'; // <- Reemplazar por tu IP/Dominio
```

### B. Cambiar la URL en caliente desde el Celular (Para pruebas rápidas)
Si la aplicación ya está instalada en tu teléfono y necesitas reconfigurar el backend sin volver a compilar:
1. Abre la aplicación en tu teléfono y ve a la **pantalla de Login**.
2. **Método del Logo:** Presiona **5 veces consecutivas** sobre el logo de la municipalidad/icono principal.
3. **Método de Versión:** Mantén **presionado por 2 segundos (clic largo)** el texto de la versión (`v1.0.0`) en la parte inferior de la pantalla.
4. Se abrirá la ventana de **Configuración de Servidor**. Escribe la dirección del backend (ej. `http://192.168.1.100:8000`) y haz clic en **Guardar**.

---

## 🚀 Compilación y Ejecución

Navega a la carpeta del proyecto `appMuni/` en tu consola y utiliza los siguientes comandos:

### Ejecutar en Modo Debug (Pruebas con Hot Reload)
Para correr la app en tu celular físico con cambios en tiempo real:
```bash
# Iniciar seleccionando tu dispositivo de la lista
flutter run

# O forzar la ejecución directa en tu celular usando su ID/Nombre (ej. ca95b69e o 2201122G)
flutter run -d ca95b69e
```

### Compilar APK de Producción (Release)
Para generar el archivo instalador final `.apk` para distribución:
```bash
flutter build apk --release
```
El archivo compilado se guardará en la ruta:
`build/app/outputs/flutter-apk/app-release.apk`
