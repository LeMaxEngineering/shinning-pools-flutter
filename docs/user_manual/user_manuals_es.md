# Shinning Pools - Manual de Usuario (Español)

"El objetivo de esta aplicación es enfocarse en el seguimiento del 'Mantenimiento', lo que asegurará que entregue su valor principal: hacer que el mantenimiento de piscinas sea fácil, rastreable y profesional tanto para empresas como para empleados."

# Shinning Pools - Manual de Usuario

¡Bienvenido! Por favor selecciona tu idioma preferido para el manual de usuario:

- [English User Manual](user_manuals_en.md)
- [Manual de Usuario en Español](user_manuals_es.md)
- [Manuel d'Utilisateur en Français](user_manuals_fr.md)

> **Nota:** Todos los manuales se mantienen actualizados con las últimas funciones e información de solución de problemas. Si notas alguna información desactualizada, por favor contacta al equipo de soporte.

## Tabla de Contenidos

1. [Comenzando](#comenzando)
2. [Manual de Usuario Root](#manual-de-usuario-root)
3. [Manual de Usuario Administrador](#manual-de-usuario-administrador)
4. [Manual de Usuario Cliente](#manual-de-usuario-cliente)
5. [Manual de Usuario Asociado](#manual-de-usuario-asociado)
6. [Solución de Problemas](#solución-de-problemas)

---

## Comenzando

### Configuración Inicial

1. **Acceder a la Aplicación**
   - Abre tu navegador web y navega a la aplicación Shinning Pools
   - La aplicación está optimizada para Chrome, Firefox y Safari

2. **Creación de Cuenta**
   - Haz clic en "Registrarse" en la pantalla de inicio de sesión
   - Ingresa tu dirección de correo electrónico y crea una contraseña segura
   - Completa la verificación por correo electrónico (revisa tu bandeja de entrada)
   - Completa la información de tu perfil

3. **Asignación de Rol**
   - Los nuevos usuarios comienzan con rol "Cliente" por defecto
   - Para convertirte en administrador de empresa, registra tu empresa (ver Manual de Cliente)
   - Los usuarios root están preconfigurados por administradores del sistema

### Proceso de Inicio de Sesión

1. **Inicio de Sesión Regular**
   - Ingresa tu correo electrónico y contraseña
   - Haz clic en "Iniciar Sesión"
   - Serás redirigido a tu dashboard específico según tu rol

2. **Inicio de Sesión con Google**
   - Haz clic en "Iniciar sesión con Google"
   - Autoriza la aplicación
   - Completa la configuración del perfil si es la primera vez

3. **Recuperación de Contraseña**
   - Haz clic en "¿Olvidaste tu contraseña?" en la pantalla de inicio de sesión
   - Ingresa tu dirección de correo electrónico
   - Revisa tu bandeja de entrada para las instrucciones de restablecimiento

---

## Manual de Usuario Root

### Descripción General
Los usuarios root tienen acceso completo al sistema y gestionan toda la plataforma, incluyendo aprobaciones de empresas, gestión de usuarios y configuración del sistema.

### Características del Dashboard

#### **Gestión de Empresas**
- **Ver Todas las Empresas**: Accede a la lista completa de empresas registradas
- **Estadísticas de Empresas**: Ve el resumen de empresas pendientes, aprobadas y suspendidas
- **Búsqueda y Filtrado**: Encuentra empresas específicas por nombre, correo electrónico o estado

#### **Acciones de Empresa**
1. **Aprobar Empresa**
   - Navega a la Lista de Empresas
   - Encuentra la empresa pendiente
   - Haz clic en el botón "Aprobar"
   - El propietario de la empresa se convierte automáticamente en rol Administrador

2. **Editar Detalles de Empresa**
   - Haz clic en el menú de tres puntos (⋮) junto a una empresa
   - Selecciona "Editar"
   - Modifica la información de la empresa
   - Guarda los cambios

3. **Suspender/Reactivar Empresa**
   - Usa el menú de acciones para suspender empresas activas
   - Proporciona la razón de suspensión cuando se solicite
   - Reactiva empresas suspendidas según sea necesario

4. **Eliminar Empresa**
   - Usa el menú de acciones para eliminar empresas
   - Confirma la eliminación (esta acción no se puede deshacer)
   - Los usuarios asociados vuelven al rol Cliente

#### **Gestión de Usuarios**
- **Ver Todos los Usuarios**: Accede al directorio completo de usuarios
- **Estadísticas de Usuarios**: Monitorea la actividad y roles de usuarios
- **Gestión de Roles**: Asigna y modifica roles de usuarios
- **Gestión de Cuentas**: Maneja problemas de cuentas de usuarios

#### **Configuración del Sistema**
- **Configuración de Plataforma**: Configura configuraciones de todo el sistema
- **Reglas de Seguridad**: Gestiona políticas de seguridad de Firestore
- **Monitoreo de Rendimiento**: Rastrea el rendimiento del sistema
- **Gestión de Respaldo**: Supervisa procedimientos de respaldo de datos

### Mejores Prácticas
- Monitoreo regular del sistema
- Gestión proactiva de seguridad
- Flujo de trabajo de aprobación de empresas
- Soporte y entrenamiento de usuarios

---

## Manual de Usuario Administrador

### Descripción General
Los administradores de empresa gestionan las operaciones de su empresa, incluyendo gestión de clientes, asignaciones de trabajadores, planificación de rutas y entrega de servicios.

### Características del Dashboard

#### **Resumen de Empresa**
- **Dashboard de Estadísticas**: Ve métricas clave (clientes, piscinas, trabajadores, rutas)
- **Actividad Reciente**: Monitorea mantenimientos recientes y completaciones de rutas
- **Métricas de Rendimiento**: Rastrea indicadores de rendimiento de la empresa

#### **Gestión de Clientes**
1. **Agregar Nuevo Cliente**
   - Navega a la sección Clientes
   - Haz clic en "Agregar Cliente"
   - Ingresa la información del cliente:
     - Nombre y detalles de contacto
     - Información de dirección
     - Requisitos especiales
   - Sube foto del cliente (opcional)
   - Guarda el registro del cliente

2. **Gestión de Lista de Clientes**
   - Ve todos los clientes de la empresa
   - Busca y filtra clientes
   - Edita información del cliente
   - Ve historial de mantenimiento del cliente

3. **Vinculación de Clientes**
   - Cuando los clientes se registran con correo electrónico coincidente, se vinculan automáticamente
   - Los clientes no vinculados pueden gestionarse por separado
   - El estado de vinculación se indica claramente en la interfaz

#### **Gestión de Piscinas**
1. **Agregar Nueva Piscina**
   - Navega a la sección Piscinas
   - Haz clic en "Agregar Piscina"
   - Ingresa detalles de la piscina:
     - Nombre/identificador de piscina
     - Dirección y ubicación
     - Tipo y dimensiones de piscina
     - Costo mensual de mantenimiento
     - Requisitos especiales
   - Sube foto de la piscina (opcional)
   - Envía para procesamiento

2. **Sistema de Dimensiones de Piscina**
El sistema ahora admite análisis inteligente de dimensiones de piscina:

**💡 Mejores Prácticas**

1. **Para Piscinas Cuadradas/Rectangulares**: Usa formato de dimensiones `LargoxAncho` (ej., `25x15`)
2. **Para Piscinas Circulares**: Ingresa el área directamente (ej., `450`)
3. **Para Piscinas Irregulares**: Ingresa el área total (ej., `320.5`)
4. **Incluye Decimales**: Para mediciones precisas (ej., `25.75x12.5`)

**⚠️ Notas Importantes**

- El sistema almacena el valor calculado final como número en la base de datos
- Al editar piscinas existentes, se muestra el número almacenado
- Para formato de dimensiones (`LxA`), el sistema calcula y almacena el área total
- Todas las mediciones se muestran con unidades `m²` en la interfaz

3. **Seguimiento de Mantenimiento de Piscinas**
   - Ve registros de mantenimiento recientes (últimos 20)
   - Filtra mantenimiento por piscina, estado y fecha
   - Accede a información detallada de mantenimiento
   - Monitorea tasas de finalización de mantenimiento

#### **Gestión de Trabajadores**
1. **Invitar Trabajadores**
   - Navega a la sección Trabajadores
   - Haz clic en "Invitar Trabajador"
   - Ingresa la dirección de correo electrónico del trabajador
   - Agrega mensaje personal (opcional)
   - Envía invitación

2. **Requisitos de Invitación de Trabajador**
   - El trabajador debe tener cuenta registrada
   - El trabajador debe tener rol "Cliente"
   - El trabajador no puede tener piscinas registradas
   - El trabajador debe aceptar la invitación

3. **Proceso de Incorporación de Trabajador**
   - El trabajador recibe notificación de invitación
   - El trabajador revisa detalles de la invitación
   - El trabajador acepta o rechaza la invitación
   - El rol cambia a "Trabajador" al aceptar

4. **Características de Gestión de Trabajadores**
   - Ve todos los trabajadores de la empresa
   - Envía recordatorios de invitación (enfriamiento de 24 horas)
   - Exporta datos de trabajadores (formato CSV/JSON)
   - Monitorea rendimiento de trabajadores

#### **Gestión de Rutas**
1. **Crear Rutas**
   - Navega a la sección Rutas
   - Haz clic en "Crear Ruta"
   - Selecciona piscinas para la ruta
   - Asigna trabajador a la ruta
   - Establece parámetros de ruta

2. **Optimización de Rutas**
   - Usa integración de Google Maps para rutas óptimas
   - Inicia rutas desde ubicación del usuario
   - Optimiza para tiempo y distancia
   - Ve visualización de ruta en el mapa

3. **Monitoreo de Rutas**
   - Rastrea estado de finalización de ruta
   - Monitorea progreso del trabajador
   - Ve datos históricos de ruta
   - Accede a análisis de rendimiento de ruta

#### **Gestión de Mantenimiento**
1. **Lista de Mantenimiento Reciente**
   - Ve últimos 20 registros de mantenimiento
   - Filtra por piscina, estado y rango de fechas
   - Accede a información detallada de mantenimiento
   - Monitorea tasas de finalización de mantenimiento

2. **Detalles de Mantenimiento**
   - Ve registros de mantenimiento completos
   - Datos de uso de químicos y calidad del agua
   - Actividades de mantenimiento físico
   - Seguimiento de costos e información de facturación

3. **Reportes de Mantenimiento**
   - Genera reportes de finalización de mantenimiento
   - Rastrea uso de químicos y costos
   - Monitorea tendencias de calidad del agua
   - Analiza eficiencia de mantenimiento

#### **Reportes y Análisis**
- **Reportes de Mantenimiento**: Genera reportes de servicio
- **Análisis de Rendimiento**: Ve rendimiento de equipo y ruta
- **Reportes de Clientes**: Analiza satisfacción del cliente
- **Reportes Financieros**: Rastrea facturación e ingresos
- **Funcionalidad de Exportación**: Descarga datos en formato CSV/JSON

### Mejores Prácticas
- Comunicación regular con clientes
- Programación proactiva de mantenimiento
- Entrenamiento y supervisión de equipo
- Control de calidad y estándares de servicio

---

## Manual de Usuario Cliente

### Descripción General
Los clientes gestionan su información de piscina, ven reportes de mantenimiento y se comunican con su proveedor de servicios.

### Características del Dashboard

#### **Registro de Empresa**
1. **Registrar Tu Empresa**
   - Haz clic en "Registrar Empresa" en el dashboard
   - Completa la información de la empresa:
     - Nombre de la empresa
     - Dirección
     - Número de teléfono
     - Descripción
   - Envía para aprobación
   - Espera la aprobación del usuario root

2. **Estado de Registro**
   - "Pendiente de Aprobación": Tu solicitud está siendo revisada
   - "Aprobada": Ahora puedes acceder a funciones de administrador
   - "Rechazada": Contacta soporte para asistencia

#### **Recibir Invitación de Trabajador**
Si un administrador de empresa te invita a convertirte en trabajador, verás una notificación en tu dashboard.
1. **Revisar**: Haz clic en la notificación para revisar los detalles de la invitación.
2. **Responder**: Puedes elegir **Aceptar** o **Rechazar** la invitación.
   - **Aceptar** cambiará tu rol a "Trabajador" y te dará acceso a las rutas y tareas de la empresa.
   - **Rechazar** no hará cambios en tu cuenta.

#### **Gestión de Piscinas**
1. **Agregar Nueva Piscina**
   - Navega a la sección Piscinas
   - Haz clic en "Agregar Piscina"
   - Ingresa detalles de la piscina:
     - Nombre/identificador de piscina
     - Tamaño y tipo
     - Detalles de ubicación
     - Requisitos especiales
   - Envía para procesamiento

2. **Monitoreo de Piscinas**
   - Ve historial de mantenimiento de piscinas
   - Revisa reportes de calidad del agua
   - Monitorea estado del equipo
   - Solicita servicios adicionales

#### **Reportes y Comunicación**
- **Reportes de Servicio**: Ve reportes detallados de mantenimiento
- **Información de Facturación**: Revisa facturas de servicio
- **Comunicación**: Contacta a tu proveedor de servicios
- **Comentarios**: Proporciona calificaciones y comentarios del servicio

#### **Gestión de Perfil**
- **Información Personal**: Actualiza detalles de contacto
- **Preferencias**: Establece preferencias de notificación
- **Seguridad**: Cambia contraseña y configuraciones de seguridad

### Mejores Prácticas
- Mantén la información de piscinas actualizada
- Revisa reportes de mantenimiento regularmente
- Comunica requisitos especiales oportunamente
- Proporciona comentarios para mejorar el servicio

---

## Manual de Usuario Asociado

### Descripción General
Los usuarios asociados (trabajadores de campo) ejecutan rutas de mantenimiento, registran actividades de servicio y actualizan el estado de las piscinas.

### Características del Dashboard

#### **Seguimiento de Mantenimiento Reciente**
1. **Ver Mantenimiento Reciente**
   - Accede a la sección "Mantenimiento Reciente" en la pestaña Reportes
   - Ve últimos 20 registros de mantenimiento que has realizado
   - Filtra por piscina, estado y rango de fechas
   - Ve direcciones de piscinas y nombres de clientes claramente mostrados

2. **Detalles de Mantenimiento**
   - Haz clic en cualquier registro de mantenimiento para vista detallada
   - Revisa uso de químicos y datos de calidad del agua
   - Verifica actividades de mantenimiento físico realizadas
   - Accede a notas y observaciones de mantenimiento

#### **Gestión de Rutas**
1. **Ver Rutas Asignadas**
   - Verifica asignaciones de ruta diarias
   - Ve detalles de ruta e información de piscinas
   - Accede a información de contacto del cliente
   - Revisa instrucciones especiales

2. **Ejecución de Ruta**
   - Inicia ruta cuando comiences a trabajar
   - Actualiza progreso mientras completas piscinas
   - Registra cualquier problema o retraso
   - Marca ruta como completa

3. **Integración de Mapas**
   - Usa mapas interactivos para navegación de ruta
   - Ve ubicaciones de piscinas con marcadores personalizados
   - Accede a direcciones de ruta optimizadas
   - Rastrea tu ubicación actual

#### **Mantenimiento de Piscinas**
1. **Registro de Servicio**
   - Selecciona piscina de la ruta
   - Registra actividades de mantenimiento:
     - Niveles y uso de químicos
     - Trabajo de equipo realizado
     - Verificaciones de calidad del agua
     - Observaciones generales
   - Agrega fotos si es necesario
   - Envía reporte de servicio

2. **Características del Formulario de Mantenimiento**
   - Seguimiento completo de químicos
   - Lista de verificación de mantenimiento físico
   - Registro de métricas de calidad del agua
   - Cálculo de costos y facturación
   - Programación de próximo mantenimiento

3. **Reporte de Problemas**
   - Reporta problemas de equipo
   - Nota problemas de calidad del agua
   - Marca preocupaciones del cliente
   - Solicita acciones de seguimiento

#### **Comunicación**
- **Actualizaciones de Clientes**: Informa a clientes sobre finalización de servicio
- **Comunicación de Equipo**: Actualiza supervisores sobre progreso
- **Contactos de Emergencia**: Accede a información de contacto de emergencia
- **Notas de Servicio**: Deja notas detalladas para miembros del equipo

#### **Gestión de Perfil**
- **Información Personal**: Actualiza detalles de contacto
- **Preferencias de Trabajo**: Establece disponibilidad y preferencias
- **Seguimiento de Rendimiento**: Ve tus estadísticas de mantenimiento
- **Materiales de Entrenamiento**: Accede a recursos de entrenamiento

### Mejores Prácticas
- Completa registros de mantenimiento con precisión
- Sigue protocolos de seguridad
- Comunica problemas oportunamente
- Mantén apariencia profesional
- Actualiza progreso de ruta regularmente

---

## Solución de Problemas

### Problemas Comunes

#### **Problemas de Autenticación**
- **Problemas de Inicio de Sesión**: Verifica correo electrónico y contraseña
- **Verificación de Correo Electrónico**: Revisa carpeta de spam para correos de verificación
- **Restablecimiento de Contraseña**: Usa función "¿Olvidaste tu contraseña?"
- **Inicio de Sesión con Google**: Asegúrate de que el navegador permita ventanas emergentes

#### **Problemas de Carga de Datos**
- **Carga Lenta**: Verifica conexión a internet
- **Datos Faltantes**: Actualiza página o limpia caché
- **Actualizaciones en Tiempo Real**: Asegura conexión estable
- **Problemas de Filtro**: Limpia filtros e intenta de nuevo

#### **Problemas de Mapas y Ubicación**
- **Permisos de Ubicación**: Habilita acceso a ubicación en navegador
- **Mapa No Carga**: Verifica conexión a internet
- **Marcadores Personalizados**: Asegúrate de que los activos de imagen estén disponibles
- **Optimización de Ruta**: Verifica clave API de Google Maps

#### **Problemas de Carga de Archivos**
- **Carga de Fotos**: Verifica tamaño y formato de archivo
- **Errores CORS**: El modo de desarrollo usa método de almacenamiento alternativo
- **Formatos Soportados**: Imágenes JPG, PNG hasta tamaños razonables

#### **Problemas Técnicos**
- **Página No Carga**: Limpia caché y cookies del navegador
- **Rendimiento Lento**: Verifica conexión a internet
- **Problemas Móviles**: Usa versión de escritorio para funcionalidad completa

### Obtener Ayuda

#### **Canales de Soporte**
- **Ayuda en la Aplicación**: Usa la sección de ayuda en tu dashboard
- **Soporte por Correo Electrónico**: Contacta support@shinningpools.com
- **Soporte Telefónico**: Llama durante horas de negocio
- **Documentación**: Consulta este manual y recursos en línea

#### **Contactos de Emergencia**
- **Problemas Técnicos**: Equipo de soporte IT
- **Emergencias de Servicio**: Tu proveedor de servicios asignado
- **Preguntas de Facturación**: Departamento de cuentas

### Requisitos del Sistema

#### **Navegador Web**
- Chrome 90+ (Recomendado)
- Firefox 88+
- Safari 14+
- Edge 90+

#### **Dispositivos Móviles**
- iOS 13+ (Safari)
- Android 8+ (Chrome)
- Diseño responsivo para todos los tamaños de pantalla

#### **Conexión a Internet**
- Mínimo 1 Mbps velocidad de descarga
- Conexión estable para funciones en tiempo real
- Modo sin conexión disponible para trabajadores de campo

### Errores de Índice de Firestore
Si ves un mensaje de error como "The query requires an index" o "[cloud_firestore/failed-precondition]", significa que Firestore necesita un índice compuesto para tus filtros. Para arreglar:
1. Copia el enlace proporcionado en el mensaje de error y ábrelo en tu navegador.
2. Haz clic en "Create" en la Consola de Firebase.
3. Espera unos minutos para que se construya el índice, luego recarga la aplicación.
Si el enlace está roto, consulta la guía de administrador o contacta soporte para pasos de creación manual de índice.

---

## Referencia Rápida

### Atajos de Teclado
- **Ctrl + S**: Guardar cambios
- **Ctrl + F**: Buscar en página actual
- **Ctrl + R**: Actualizar página
- **Esc**: Cerrar diálogos

### Indicadores de Estado
- 🟢 **Activo**: Operación normal
- 🟡 **Pendiente**: Esperando acción
- 🔴 **Suspendido**: Temporalmente deshabilitado
- ⚫ **Inactivo**: No en uso

### Acciones Comunes
- **Editar**: Haz clic en icono de lápiz o menú de tres puntos
- **Eliminar**: Usa icono de basura con confirmación
- **Ver Detalles**: Haz clic en nombre del elemento
- **Exportar**: Usa icono de descarga para reportes

---

*Última Actualización: 21 de Julio de 2025*
*Versión: 1.6.9 - Correcciones del Dashboard de Trabajadores y Mejoras de Calidad de Código*

> **📝 Actualizaciones Recientes**: 
> - **Corrección de Tarjetas de Mantenimiento Reciente del Dashboard de Trabajadores (Julio 2025)**: Resuelto problema de "Dirección desconocida" implementando obtención de datos adecuada desde Firestore. Mejorada obtención de nombres de clientes y mejorada visualización de datos.
> - **Mejoras de Calidad de Código (Julio 2025)**: Corregidos 29 problemas críticos, reducidos problemas totales de 288 a 259. Mejorada calidad y mantenibilidad del código base.
> - **Integración de Base de Datos del Mapa de Mantenimiento (Julio 2025)**: Reemplazados datos simulados con datos en vivo de Firestore, agregada visualización de estado de mantenimiento real con puntos verdes/rojos.
> - **Optimización de Zoom del Mapa de Ruta Histórica (Julio 2025)**: Mejorados niveles de zoom del mapa y posicionamiento de cámara para mejor experiencia de usuario.

## Características de Mapas y Selección de Piscinas (Actualización 2025)

### Marcador de Ubicación de Usuario Personalizado
- El mapa ahora muestra tu ubicación actual con un icono personalizado (user_marker.png).
- Si no ves tu marcador de ubicación, asegúrate de que los permisos de ubicación estén habilitados y que el activo de imagen exista en assets/img/user_marker.png.

### Marcadores de Piscinas y Estado de Mantenimiento
- **Puntos Verdes**: Piscinas que han sido mantenidas hoy
- **Puntos Rojos**: Piscinas que necesitan mantenimiento
- **Marcadores Azules**: Ubicaciones generales de piscinas
- Cada marcador muestra la dirección de la piscina. Si falta la dirección, mostrará 'Sin dirección'.

### Interfaz de Selección de Piscinas
- La sección 'Piscina Seleccionada' ahora aparece inmediatamente después del cuadro de búsqueda para flujo de trabajo más fácil.
- Puedes buscar piscinas por nombre, dirección o cliente, o seleccionar desde el mapa.
- Las piscinas mantenidas muestran "(No Seleccionable)" en ventanas de información y no pueden seleccionarse para nuevo mantenimiento.

### Filtrado de Piscinas Basado en Distancia
- Los mapas pueden mostrar solo las 10 piscinas más cercanas a tu ubicación actual
- Alternar entre "Piscinas Cercanas" y "Todas las Piscinas de la Empresa"
- Cálculo inteligente de distancia usando fórmula de Haversine

## Menú de Ayuda (Cajón Lateral)

Un nuevo menú de Ayuda está disponible desde el dashboard principal para todos los roles de usuario (trabajador, administrador de empresa, cliente, root). Ábrelo usando el icono de menú en la parte superior izquierda. El menú de Ayuda proporciona:

- **Acerca de**: Versión de la aplicación, última actualización, nombre de la empresa (Lemax Engineering LLC) e información de contacto (+1 561 506 9714).
- **Verificar Actualizaciones**: Verificar si hay una nueva versión disponible.
- **Bienvenida**: Mensaje de bienvenida y descripción general de la aplicación.
- **Enlaces del Manual de Usuario**: Enlaces directos al manual de usuario (PDF), inicio rápido y guías de solución de problemas.
- **Contacto y Soporte**: Llamar o enviar correo electrónico a soporte directamente desde la aplicación.

## Características de Mantenimiento Reciente (Julio 2025)

### Mantenimiento Reciente del Dashboard de Trabajadores
- **Visualización de Dirección de Piscina**: Las direcciones de piscinas ahora se muestran correctamente como títulos principales
- **Nombres de Clientes**: Los nombres de clientes se muestran como subtítulos en lugar de "Dirección desconocida"
- **Formato de Fecha**: Las fechas se muestran en formato "Mes DD, AAAA"
- **Filtrado Avanzado**: Filtrar por piscina, estado y rango de fechas
- **Fuente de Datos**: Usa obtención de datos local para mejor confiabilidad

### Seguimiento de Mantenimiento de Administrador de Empresa
- **Lista de Mantenimiento Reciente**: Ver últimos 20 registros de mantenimiento en pestaña Piscinas
- **Filtrado Integral**: Filtrar por piscina, trabajador, estado y fecha
- **Detalles de Mantenimiento**: Acceder a información detallada de mantenimiento
- **Monitoreo de Rendimiento**: Rastrear tasas de finalización de mantenimiento

## Arquitectura del Sistema de Mantenimiento (Julio 2025)

### Registros de Mantenimiento
- **Seguimiento Integral**: Uso de químicos, mantenimiento físico, métricas de calidad del agua
- **Cálculo de Costos**: Cálculo automático de costos basado en materiales utilizados
- **Programación de Próximo Mantenimiento**: Programación automática basada en tipo de servicio
- **Documentación Fotográfica**: Subir fotos para registros de mantenimiento

### Seguridad y Control de Acceso
- **Acceso Basado en Roles**: Diferentes permisos para diferentes roles de usuario
- **Aislamiento de Empresa**: Los usuarios solo pueden acceder a datos de su empresa
- **Validación de Mantenimiento**: Previene registros duplicados de mantenimiento por piscina por día
- **Rastro de Auditoría**: Historial completo de todas las actividades de mantenimiento

## Estado de Calidad de Código y Rendimiento (Julio 2025)
- **Análisis Estático:** ✅ Código base limpio con 259 problemas totales (reducidos de 288)
- **Cobertura de Pruebas:** ✅ 78 pruebas pasando, 0 fallas (100% tasa de aprobación)
- **Compilación:** ✅ 0 errores, rendimiento estable
- **Rendimiento:** ✅ Estable y responsivo en todas las plataformas
- **Multiplataforma:** ✅ Soporte completo para Web, Android, iOS, Desktop
- **Integración de Datos:** ✅ Obtención robusta de datos de clientes con manejo de errores

**Recordatorio:** Siempre verifica las últimas actualizaciones de la aplicación y documentación para asegurar que tengas la información y características más actuales.
