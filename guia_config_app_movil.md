# Guía: Consumo de API para Configuración de la App Móvil

Este endpoint ha sido diseñado específicamente para que la aplicación móvil de Seguridad Ciudadana pueda obtener el logo e información institucional de forma pública (sin necesidad de estar autenticado).

## 1. Detalles del Endpoint

*   **URL:** `{{BASE_URL}}/api/seguridad-ciudadana/config/public-info`
*   **Método:** `GET`
*   **Autenticación:** Ninguna (Público).

## 2. Ejemplo de Respuesta (JSON)

```json
{
    "success": true,
    "data": {
        "id": 1,
        "name": "MUNICIPALIDAD DISTRITAL DE EJEMPLO",
        "ruc": "20123456789",
        "address": "Av. Principal 123",
        "phone": "01 2345678",
        "email": "contacto@entidad.gob.pe",
        "website": "www.entidad.gob.pe",
        "logo": "organization/logo_name.png",
        "logo_url": "http://api-intra.test/storage/organization/logo_name.png",
        "responsable_name": "Ing. Juan Perez",
        "responsable_cargo": "Gerente de Seguridad",
        "created_at": "2026-03-03T15:38:39.000000Z",
        "updated_at": "2026-04-03T01:08:48.000000Z"
    }
}
```

## 3. Implementación en Flutter (Dart)

Para usar este endpoint en la aplicación móvil, se recomienda cargarlo en el inicio de la app (`SplashScreen` o `Main`).

### Ejemplo de Servicio

```dart
import 'dart:convert';
import 'http://http.dart' as http;

class ConfigService {
  final String baseUrl = "http://tu-servidor-api.site";

  Future<Map<String, dynamic>?> getPublicConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/seguridad-ciudadana/config/public-info'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
    } catch (e) {
      print("Error cargando configuración: $e");
    }
    return null;
  }
}
```

### Ejemplo de Uso en UI (Branding)

```dart
// En tu pantalla de Login
if (config != null) {
  Image.network(
    config!['logo_url'], // URL absoluta lista para usar
    height: 100,
    placeholder: (context, url) => CircularProgressIndicator(),
    errorWidget: (context, url, error) => Icon(Icons.business),
  );
  Text(config!['name']); // "MUNICIPALIDAD DISTRITAL DE..."
}
```

## 4. Mejores Prácticas

1.  **Carga Inicial:** Llama a este endpoint al abrir la aplicación para que todos los elementos visuales (logo, colores si existieran, nombre) se ajusten a la entidad correspondiente.
2.  **Manejo de Errores:** Siempre ten un "Placeholder" o un logo por defecto en la app por si la conexión falla o el registro en base de datos aún no se ha creado.
3.  **Uso de `logo_url`:** Evita usar el campo `logo` (que es solo la ruta relativa). Usa siempre `logo_url`, ya que el backend la genera dinámicamente con la URL completa del servidor.
4.  **Cache:** Puedes guardar estos datos en local (SharedPreferences) para que la siguiente vez que se abra la app (sin internet), el branding siga funcionando.

> [!TIP]
> Si en el futuro necesitas más datos públicos para la app móvil (ej: teléfonos de emergencia, enlaces a redes sociales), puedes agregarlos en la tabla `organization_settings` y automáticamente aparecerán en este endpoint.
