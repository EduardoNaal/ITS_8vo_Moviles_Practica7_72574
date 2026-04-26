# Planificación de Pruebas — App de Alarma con Cancelación por Voz

**Proyecto:** Práctica #7 — Manejo de Hardware  
**Framework:** Flutter  
**Alumno:** Eduardo — ITS 8vo Semestre  
**Fecha:** 24 de abril de 2026  

---

## Tabla de Contenidos

1. [Pruebas Unitarias](#1-pruebas-unitarias)
2. [Pruebas de Integración](#2-pruebas-de-integración)
3. [Pruebas de Seguridad y Privacidad](#3-pruebas-de-seguridad-y-privacidad)
4. [Pruebas de Usabilidad de la Interfaz Gráfica](#4-pruebas-de-usabilidad-de-la-interfaz-gráfica)
5. [Técnicas de Pruebas Implementables](#5-técnicas-de-pruebas-implementables)
6. [Matriz de Trazabilidad](#6-matriz-de-trazabilidad)
7. [Resultados de Pruebas Ejecutadas](#7-resultados-de-pruebas-ejecutadas)

---

## 1. Pruebas Unitarias

Las pruebas unitarias verifican el correcto funcionamiento de **unidades individuales de código** (funciones, métodos, clases) de forma aislada, sin dependencias externas.

### 1.1 Pruebas Unitarias Identificadas

#### A) Modelo de Alarma (`AlarmModel`)

| ID | Prueba | Archivo | Descripción |
|----|--------|---------|-------------|
| PU-01 | Constructor con valores por defecto | `alarm_model_test.dart` | Verifica que `isEnabled=true`, `voiceCommand='detener'`, `daysOfWeek` vacío |
| PU-02 | Constructor con parámetros personalizados | `alarm_model_test.dart` | Verifica que acepta todos los parámetros correctamente |
| PU-03 | `timeString` formato AM | `alarm_model_test.dart` | 7:05 → `"7:05 AM"` |
| PU-04 | `timeString` formato PM | `alarm_model_test.dart` | 14:30 → `"2:30 PM"` |
| PU-05 | `timeString` medianoche (0:00) | `alarm_model_test.dart` | 0:00 → `"12:00 AM"` |
| PU-06 | `timeString` mediodía (12:00) | `alarm_model_test.dart` | 12:00 → `"12:00 PM"` |
| PU-07 | `timeString` minuto con padding | `alarm_model_test.dart` | 9:03 → `"9:03 AM"` (no "9:3") |
| PU-08 | `daysString` sin días | `alarm_model_test.dart` | → `"Una vez"` |
| PU-09 | `daysString` todos los días | `alarm_model_test.dart` | → `"Todos los días"` |
| PU-10 | `daysString` Lun a Vie | `alarm_model_test.dart` | → `"Lun a Vie"` |
| PU-11 | `daysString` fin de semana | `alarm_model_test.dart` | → `"Sáb, Dom"` |
| PU-12 | `daysString` días dispersos | `alarm_model_test.dart` | → `"Lun, Mié, Vie"` |
| PU-13 | `toJson` completo | `alarm_model_test.dart` | Verifica todos los campos del mapa JSON |
| PU-14 | `fromJson` reconstrucción | `alarm_model_test.dart` | JSON → objeto con valores correctos |
| PU-15 | `fromJson` campos faltantes | `alarm_model_test.dart` | Valores por defecto cuando faltan campos |
| PU-16 | Ciclo `toJson → fromJson` | `alarm_model_test.dart` | Datos intactos ida y vuelta |
| PU-17 | `serialize` produce JSON válido | `alarm_model_test.dart` | String parseable por `jsonDecode` |
| PU-18 | Ciclo `serialize → deserialize` | `alarm_model_test.dart` | String ida y vuelta preserva datos |
| PU-19 | `deserialize` JSON malformado | `alarm_model_test.dart` | Lanza `FormatException` |
| PU-20 | `copyWith` copia idéntica | `alarm_model_test.dart` | Sin cambios = clone exacto |
| PU-21 | `copyWith` cambios parciales | `alarm_model_test.dart` | Solo modifica campos especificados |
| PU-22 | `copyWith` independencia de daysOfWeek | `alarm_model_test.dart` | Modificar copia no afecta original |

#### B) Provider de Estado (`AlarmProvider`)

| ID | Prueba | Archivo | Descripción |
|----|--------|---------|-------------|
| PU-23 | Estado inicial vacío | `alarm_provider_test.dart` | `alarms` inicia como lista vacía |
| PU-24 | `addAlarm` agrega una alarma | `alarm_provider_test.dart` | Lista pasa de 0 a 1 elemento |
| PU-25 | `addAlarm` múltiples alarmas | `alarm_provider_test.dart` | Lista acumula correctamente |
| PU-26 | `updateAlarm` modifica existente | `alarm_provider_test.dart` | Cambia hora y label |
| PU-27 | `updateAlarm` ID inexistente | `alarm_provider_test.dart` | No modifica nada, no lanza error |
| PU-28 | `deleteAlarm` elimina correcta | `alarm_provider_test.dart` | Remueve por ID, mantiene las demás |
| PU-29 | `deleteAlarm` ID inexistente | `alarm_provider_test.dart` | No afecta la lista |
| PU-30 | `toggleAlarm` alterna estado | `alarm_provider_test.dart` | true→false→true |
| PU-31 | `toggleAlarm` ID inexistente | `alarm_provider_test.dart` | No afecta nada |
| PU-32 | `addAlarm` notifica listeners | `alarm_provider_test.dart` | `notifyListeners` se invoca |
| PU-33 | `deleteAlarm` notifica listeners | `alarm_provider_test.dart` | Listeners reciben notificación |
| PU-34 | `toggleAlarm` notifica listeners | `alarm_provider_test.dart` | Listeners reciben notificación |
| PU-35 | `updateAlarm` notifica listeners | `alarm_provider_test.dart` | Listeners reciben notificación |
| PU-36 | Flujo CRUD completo | `alarm_provider_test.dart` | add → update → toggle → delete |
| PU-37 | Alarmas independientes | `alarm_provider_test.dart` | Toggle de una no afecta otras |

#### C) Lógica de Comparación de Voz

| ID | Prueba | Archivo | Descripción |
|----|--------|---------|-------------|
| PU-38 | Coincidencia exacta | `voice_matching_test.dart` | `"detener"` = `"detener"` |
| PU-39 | Case insensitive | `voice_matching_test.dart` | `"DETENER"` = `"detener"` |
| PU-40 | Trim de espacios | `voice_matching_test.dart` | `"  detener  "` = `"detener"` |
| PU-41 | Comando dentro de frase | `voice_matching_test.dart` | `"quiero detener la alarma"` contiene `"detener"` |
| PU-42 | Comando al inicio | `voice_matching_test.dart` | `"detener por favor"` |
| PU-43 | Comando al final | `voice_matching_test.dart` | `"por favor detener"` |
| PU-44 | No coincidencia | `voice_matching_test.dart` | `"hola mundo"` ≠ `"detener"` |
| PU-45 | Texto vacío | `voice_matching_test.dart` | `""` ≠ `"detener"` |
| PU-46 | Texto parcial | `voice_matching_test.dart` | `"deten"` ≠ `"detener"` |
| PU-47 | Frases en español | `voice_matching_test.dart` | `"ya desperté"`, `"cállate"`, `"silencio"` |
| PU-48 | STT con puntuación | `voice_matching_test.dart` | `"detener."` = `"detener"` |

#### D) Servicios Core (`AudioService` y `SpeechService`) [NUEVO]

| ID | Prueba | Archivo | Descripción |
|----|--------|---------|-------------|
| PU-49 | AudioService Singleton | `audio_service_test.dart` | Verifica que múltiples instancias apunten al mismo objeto en memoria para prevenir audios duplicados |
| PU-50 | Watchdog Timer Reactivación | `speech_service_test.dart` | Verifica que el timer de 2 segundos de escucha force la reactivación si el OS duerme el proceso |

**Total pruebas unitarias identificadas: 50**  
**Implementadas y ejecutadas: 59** (incluyendo sub-assertions)

---

## 2. Pruebas de Integración

Las pruebas de integración verifican la **interacción correcta entre dos o más componentes** del sistema trabajando juntos.

### 2.1 Pruebas de Integración Identificadas

#### A) Persistencia ↔ Provider

| ID | Prueba | Componentes Involucrados | Descripción |
|----|--------|--------------------------|-------------|
| PI-01 | Guardar y recuperar alarmas | `AlarmProvider` + `StorageService` + `SharedPreferences` | Crear alarmas, cerrar provider, recrear y verificar que se cargan |
| PI-02 | Persistencia después de toggle | `AlarmProvider` + `StorageService` | Toggle alarma → recargar → estado persiste |
| PI-03 | Persistencia después de delete | `AlarmProvider` + `StorageService` | Eliminar → recargar → alarma ya no existe |
| PI-04 | Persistencia con datos complejos | `AlarmModel` + `StorageService` | Guardar alarma con todos los campos (días, voz, label) y restaurar |

#### B) Alarma Sonando ↔ Servicios de Hardware

| ID | Prueba | Componentes Involucrados | Descripción |
|----|--------|--------------------------|-------------|
| PI-05 | Disparo de alarma por hora | `HomeScreen._checkAlarms` + `AlarmProvider` + `AlarmRingingScreen` | Crear alarma a hora actual → verificar que se dispara la pantalla |
| PI-06 | Audio + Vibración simultáneos | `AudioService` + `Vibration` | Al sonar alarma, audio Y vibración se activan juntos |
| PI-07 | Voz cancela audio y vibración | `SpeechService` + `AudioService` + `Vibration` | Comando de voz reconocido → audio Y vibración se detienen |
| PI-08 | Botón manual cancela todo | `AlarmRingingScreen` + `AudioService` + `Vibration` + `SpeechService` | Botón cancelar → audio, vibración y micrófono se detienen |

#### C) Navegación ↔ Estado

| ID | Prueba | Componentes Involucrados | Descripción |
|----|--------|--------------------------|-------------|
| PI-09 | Crear alarma desde pantalla | `AlarmEditScreen` + `AlarmProvider` + `AlarmsScreen` | Llenar form → guardar → aparece en la lista |
| PI-10 | Editar alarma existente | `AlarmsScreen` + `AlarmEditScreen` + `AlarmProvider` | Tap alarma → editar → cambios reflejados |
| PI-11 | Eliminar por deslizar | `AlarmsScreen` + `AlarmProvider` | Swipe → alarma eliminada de lista y storage |
| PI-12 | Navegación entre tabs | `HomeScreen` + `BottomNavigationBar` | Cambiar entre 4 tabs mantiene estado de cada pantalla |

#### D) Verificación de Días ↔ Alarma

| ID | Prueba | Componentes Involucrados | Descripción |
|----|--------|--------------------------|-------------|
| PI-13 | Alarma solo Lun-Vie no suena en sábado | `_checkAlarms` + `AlarmModel.daysOfWeek` | Alarma configurada L-V → no se dispara en fin de semana |
| PI-14 | Alarma "Una vez" suena cualquier día | `_checkAlarms` + `AlarmModel` | Sin días seleccionados → suena el día actual |

| PI-15 | Sincronización Frase Maestra | `StorageService` + `AlarmProvider` + `AlarmModel` | Cambio de defaultVoiceCommand se guarda, recarga y aplica a nuevas alarmas |

**Total pruebas de integración identificadas: 15**

---

## 3. Pruebas de Seguridad y Privacidad

### 3.1 Análisis de Amenazas (STRIDE)

| Categoría STRIDE | Amenaza Identificada | Nivel de Riesgo | Mitigación Actual |
|---|---|---|---|
| **S**poofing (Suplantación) | Otra persona usa un comando de voz similar para cancelar la alarma | Bajo | El comando es personalizable, el usuario elige frases únicas |
| **T**ampering (Manipulación) | Modificación de datos de alarmas en SharedPreferences | Bajo | Datos locales, no hay servidor externo expuesto |
| **R**epudiation (Repudio) | N/A — no hay transacciones que requieran auditoría | N/A | — |
| **I**nformation Disclosure (Filtración) | Grabaciones de voz podrían contener información sensible | Medio | El audio NO se almacena, solo se procesa en tiempo real |
| **D**enial of Service (Denegación) | La app podría agotar batería con escucha continua de micrófono | Bajo | La escucha solo se activa al sonar la alarma, no permanentemente |
| **E**levation of Privilege (Elevación) | Permisos de micrófono podrían ser explotados | Bajo | Se solicitan permisos solo cuando se necesitan |

### 3.2 Plan de Pruebas de Seguridad

| ID | Prueba | Categoría | Procedimiento | Resultado Esperado |
|----|--------|-----------|---------------|-------------------|
| PS-01 | Datos almacenados sin encriptación | Confidencialidad | Inspeccionar SharedPreferences en el dispositivo | Los datos de alarmas no contienen información sensible (solo hora, días, etiqueta) |
| PS-02 | Permisos mínimos necesarios | Principio de menor privilegio | Revisar `AndroidManifest.xml` | Solo permisos estrictamente necesarios: `RECORD_AUDIO`, `VIBRATE`, `POST_NOTIFICATIONS` |
| PS-03 | Audio de voz no se persiste | Privacidad | Verificar que el audio del micrófono no se guarda en disco | `speech_to_text` procesa en memoria, no crea archivos de audio |
| PS-04 | Sin comunicación a servidores externos | Privacidad | Monitorear tráfico de red durante uso normal | No hay peticiones HTTP a servidores externos (excepto fallback de audio) |
| PS-05 | Comando de voz almacenado localmente | Privacidad | Verificar que el comando de voz no se envía a la nube | `speech_to_text` usa el motor nativo de Android (on-device) |
| PS-06 | Permisos denegados no crashean la app | Robustez | Denegar permiso de micrófono → usar la app | La app muestra "Micrófono no disponible" y permite cancelación manual |
| PS-07 | Resistencia a inyección de datos | Integridad | Insertar JSON malformado en SharedPreferences | La app maneja la excepción sin crashear |
| PS-08 | Validación de entrada del comando de voz | Integridad | Ingresar strings extremadamente largos, caracteres especiales, emojis como comando | La app acepta sin crash y la comparación funciona |

### 3.3 Plan de Pruebas de Privacidad

| ID | Aspecto de Privacidad | Verificación | Estado |
|----|----------------------|--------------|--------|
| PP-01 | **Recolección de datos** | ¿Qué datos se recolectan? | Solo hora, días, etiqueta y comando de voz (texto plano local) |
| PP-02 | **Almacenamiento de datos** | ¿Dónde se almacenan? | SharedPreferences (sandbox de la app, no accesible por otras apps) |
| PP-03 | **Transmisión de datos** | ¿Se envían datos a servidores? | No. Todo es local. El STT usa motor on-device de Android |
| PP-04 | **Grabación de audio** | ¿Se graba la voz del usuario? | No. El audio se procesa en streaming y no se persiste |
| PP-05 | **Datos biométricos** | ¿Se usa huella de voz? | No. Solo comparación textual, no identificación biométrica |
| PP-06 | **Consentimiento** | ¿Se pide permiso antes de usar el micrófono? | Sí, mediante `permission_handler` y el diálogo del sistema |
| PP-07 | **Eliminación de datos** | ¿Se pueden borrar los datos? | Sí. Eliminar alarma borra todos sus datos. Desinstalar la app limpia SharedPreferences |

---

## 4. Pruebas de Usabilidad de la Interfaz Gráfica

### 4.1 Heurísticas de Nielsen Aplicadas

| # | Heurística | Aspecto a Evaluar en la App | Prueba Planificada |
|---|---|---|---|
| H1 | **Visibilidad del estado del sistema** | ¿El usuario sabe si la alarma está activa? ¿El micrófono está escuchando? | Verificar que hay indicadores visuales: switch on/off, icono de micrófono, ondas de audio |
| H2 | **Correspondencia con el mundo real** | ¿El reloj analógico se ve familiar? ¿Los días L M X J V S D son claros? | Verificar que los íconos y etiquetas son intuitivos en español |
| H3 | **Control y libertad del usuario** | ¿Se puede cancelar la alarma manualmente además de por voz? | Verificar que el botón "Cancelar alarma" siempre está visible |
| H4 | **Consistencia y estándares** | ¿La navegación por tabs sigue el patrón de Material Design? | Verificar BottomNavigationBar con 4 tabs consistentes |
| H5 | **Prevención de errores** | ¿Se puede crear una alarma sin hora? ¿Qué pasa con campos vacíos? | Verificar que el TimePicker siempre tiene valor válido |
| H6 | **Reconocimiento antes que recuerdo** | ¿Las alarmas creadas muestran toda su info en la lista? | Verificar que cada tile muestra hora, días, label y comando |
| H7 | **Flexibilidad y eficiencia** | ¿Se puede eliminar rápido con swipe? ¿Toggle rápido con switch? | Verificar gestos: swipe-to-delete, tap-to-edit, switch on/off |
| H8 | **Diseño estético y minimalista** | ¿La interfaz es limpia y sin elementos innecesarios? | Evaluar tema oscuro, tipografía, espaciado y paleta de colores |
| H9 | **Ayuda al usuario con errores** | ¿Qué muestra si el micrófono no funciona? | Verificar mensaje "Micrófono no disponible" con botón manual |
| H10 | **Ayuda y documentación** | ¿El hint "Di esta frase para cancelarla con tu voz" es claro? | Verificar texto explicativo en la pantalla de edición de alarma |

### 4.2 Pruebas de Usabilidad por Pantalla

#### Pantalla: Reloj (Tab 1)

| ID | Elemento | Prueba | Criterio de Éxito |
|----|----------|--------|-------------------|
| PUI-01 | Reloj analógico | Visibilidad de manecillas | Las 3 manecillas son distinguibles; la de segundos se mueve en tiempo real |
| PUI-02 | Hora digital | Legibilidad | Fuente grande (72px), formato 12h con AM/PM claro |
| PUI-03 | Fecha | Información contextual | Muestra día de la semana y fecha completa en español |

#### Pantalla: Alarmas (Tab 2)

| ID | Elemento | Prueba | Criterio de Éxito |
|----|----------|--------|-------------------|
| PUI-04 | Estado vacío | Feedback visual | Ícono y texto "Sin alarmas" + instrucción para crear |
| PUI-05 | Lista de alarmas | Scannability | Hora grande, label y días debajo, switch a la derecha |
| PUI-06 | Ícono de micrófono | Indicador de voz | Muestra 🎤 + el comando entre comillas si está configurado |
| PUI-07 | Swipe-to-delete | Gesto intuitivo | Fondo rojo con ícono de basura al deslizar |
| PUI-08 | FAB (+) | Acción principal | Botón flotante visible y accesible |

#### Pantalla: Editar Alarma

| ID | Elemento | Prueba | Criterio de Éxito |
|----|----------|--------|-------------------|
| PUI-09 | TimePicker | Facilidad de uso | Tap en la hora abre el picker nativo del sistema |
| PUI-10 | Selector de días | Feedback visual | Círculos que cambian de color al seleccionar |
| PUI-11 | Campo de etiqueta | Placeholder claro | Hint "Ej: Despertar, Medicina..." |
| PUI-12 | Campo de voz | Diferenciación visual | Ícono de micrófono verde, hint con ejemplos |
| PUI-13 | Hint explicativo | Comprensión | Banner verde explica para qué sirve el comando |
| PUI-14 | Botón Guardar | Visibilidad | Texto "Guardar" azul en la barra superior |

#### Pantalla: Temporizador (Tab 3)

| ID | Elemento | Prueba | Criterio de Éxito |
|----|----------|--------|-------------------|
| PUI-15 | Scroll wheels | Interacción táctil | Ruedas para h, m, s con números grandes |
| PUI-16 | Progreso circular | Feedback visual | Barra circular que decrece; rojo cuando ≤10s |
| PUI-17 | Controles | Claridad de iconos | Play/Pause/Stop con etiquetas debajo |

#### Pantalla: Cronómetro (Tab 4)

| ID | Elemento | Prueba | Criterio de Éxito |
|----|----------|--------|-------------------|
| PUI-18 | Display de tiempo | Precisión visual | Centésimas actualizándose fluidamente |
| PUI-19 | Laps coloreados | Diferenciación | Mejor vuelta en verde, peor en rojo |
| PUI-20 | Botón Vuelta/Reset | Contexto | Cambia de "Vuelta" (corriendo) a "Reset" (pausado) |

#### Pantalla: Alarma Sonando ⭐

| ID | Elemento | Prueba | Criterio de Éxito |
|----|----------|--------|-------------------|
| PUI-21 | Hora pulsante | Atención | Animación de escala que llama la atención |
| PUI-22 | Ondas de audio | Estado de escucha | Ondas animadas indican que el micrófono está activo |
| PUI-23 | Texto reconocido | Feedback en tiempo real | Muestra lo que el STT está detectando |
| PUI-24 | Indicador de escucha | Instrucción | Dice "Escuchando... di [comando]" |
| PUI-25 | Fallback sin micrófono | Accesibilidad | Muestra "Micrófono no disponible" en rojo |
| PUI-26 | Botón cancelar manual | Accesibilidad | Siempre visible, borde rojo, texto grande |
| PUI-27 | Diálogo de confirmación | Feedback | Diferencia cancelación por voz (🎤) vs manual (⏰) |

**Total pruebas de usabilidad identificadas: 27**

---

## 5. Técnicas de Pruebas Implementables

### 5.1 Técnicas de Caja Negra (Black Box)

| Técnica | Aplicación en el Proyecto | Ejemplo Concreto |
|---------|---------------------------|------------------|
| **Partición de equivalencias** | Clases de hora: AM (0-11h), PM (12-23h), bordes (0, 12, 23) | `timeString` con horas 0, 1, 11, 12, 13, 23 |
| **Valores límite** | Minutos: 0, 1, 58, 59. Horas: 0, 12, 23 | PU-03 a PU-07 prueban estos bordes |
| **Tabla de decisión** | Combinaciones de `daysOfWeek`: ningún día, L-V, S-D, todos | PU-08 a PU-12 cubren todas las combinaciones relevantes |
| **Transición de estados** | Alarma: creada → activa → sonando → cancelada | PI-05, PI-07, PI-08 verifican el flujo completo |
| **Casos de uso** | Flujo: crear alarma → suena → cancelar por voz | PI-05 + PI-07 combinados |

### 5.2 Técnicas de Caja Blanca (White Box)

| Técnica | Aplicación en el Proyecto | Ejemplo Concreto |
|---------|---------------------------|------------------|
| **Cobertura de sentencias** | Todas las ramas de `daysString` ejecutadas | PU-08 a PU-12: cada `if/return` dentro de `daysString` |
| **Cobertura de decisiones** | `if (alarm.isEnabled && hour==now.hour && minute==now.minute)` | PI-05 y PI-13 prueban true/false de cada condición |
| **Cobertura de caminos** | `_cancelAlarm(byVoice: true)` vs `_cancelAlarm(byVoice: false)` | PI-07 (por voz) y PI-08 (por botón) |
| **Prueba de ciclos** | `for (int i = 0; i < 7; i++)` en `daysString` | PU-10 y PU-12 verifican el recorrido completo del loop |

### 5.3 Técnicas Específicas para Móviles

| Técnica | Aplicación | Procedimiento |
|---------|-----------|---------------|
| **Prueba de permisos** | Micrófono, notificaciones | Denegar permisos → verificar comportamiento graceful (PS-06) |
| **Prueba de ciclo de vida** | App en background/foreground | Minimizar app mientras suena alarma → ¿se detiene? ¿se reanuda? |
| **Prueba de interrupción** | Llamada telefónica durante alarma | Recibir llamada mientras suena → ¿la app se comporta bien? |
| **Prueba de recursos** | CPU, memoria, batería | Dejar el cronómetro corriendo 30 min → medir consumo |
| **Prueba de rotación** | Cambio de orientación | Rotar pantalla en cada tab → no debe perder estado |
| **Prueba de accesibilidad** | TalkBack/VoiceOver | Activar lector de pantalla → verificar que todos los elementos son anunciados |

### 5.4 Resumen de Técnicas por Categoría

```
┌──────────────────────────────────────────────────────────────┐
│                   TÉCNICAS DE PRUEBAS                        │
├──────────────────────┬───────────────────────────────────────┤
│                      │  • Partición de equivalencias         │
│   Caja Negra         │  • Valores límite                     │
│   (Funcionalidad)    │  • Tabla de decisión                  │
│                      │  • Transición de estados              │
│                      │  • Casos de uso                       │
├──────────────────────┼───────────────────────────────────────┤
│                      │  • Cobertura de sentencias            │
│   Caja Blanca        │  • Cobertura de decisiones            │
│   (Estructura)       │  • Cobertura de caminos               │
│                      │  • Prueba de ciclos                   │
├──────────────────────┼───────────────────────────────────────┤
│                      │  • Permisos del sistema               │
│   Específicas        │  • Ciclo de vida de la app            │
│   Móviles            │  • Interrupciones (llamadas, SMS)     │
│                      │  • Consumo de recursos                │
│                      │  • Rotación de pantalla               │
│                      │  • Accesibilidad (TalkBack)           │
├──────────────────────┼───────────────────────────────────────┤
│   No Funcionales     │  • STRIDE (seguridad)                 │
│                      │  • Heurísticas de Nielsen (usabilidad)│
│                      │  • Análisis de privacidad de datos    │
└──────────────────────┴───────────────────────────────────────┘
```

---

## 6. Matriz de Trazabilidad

Relación entre **funcionalidades → pruebas**.

| Funcionalidad | Pruebas Unitarias | Pruebas Integración | Seguridad | Usabilidad |
|---|---|---|---|---|
| Reloj digital/analógico | — | — | — | PUI-01, PUI-02, PUI-03 |
| CRUD de alarmas | PU-23 a PU-37 | PI-01 a PI-04, PI-09 a PI-11 | PS-07, PS-08 | PUI-04 a PUI-08 |
| Editar alarma (form) | PU-01, PU-02 | PI-09, PI-10 | PS-08 | PUI-09 a PUI-14 |
| Formato de hora | PU-03 a PU-07 | — | — | PUI-02 |
| Días de la semana | PU-08 a PU-12 | PI-13, PI-14 | — | PUI-10 |
| Serialización/persistencia | PU-13 a PU-19 | PI-01 a PI-04 | PS-01, PS-07 | — |
| Temporizador | — | — | — | PUI-15 a PUI-17 |
| Cronómetro | — | — | — | PUI-18 a PUI-20 |
| Alarma sonando (audio+vibración) | — | PI-05 a PI-08 | PS-06 | PUI-21 |
| **Cancelación por voz** ⭐ | PU-38 a PU-48 | PI-07 | PS-03, PS-04, PS-05 | PUI-22 a PUI-27 |
| Navegación por tabs | — | PI-12 | — | H4 |
| Permisos del sistema | — | — | PS-02, PS-06 | PUI-25 |

---

## 7. Resultados de Pruebas Ejecutadas

### 7.1 Pruebas Unitarias (Automatizadas)

```
Comando: flutter test --reporter expanded
Fecha:   24 de abril de 2026
```

| Suite de Tests | Tests | Pasaron | Fallaron | Estado |
|---|---|---|---|---|
| `test/models/alarm_model_test.dart` | 25 | 25 | 0 | ✅ |
| `test/providers/alarm_provider_test.dart` | 14 | 14 | 0 | ✅ |
| `test/services/voice_matching_test.dart` | 18 | 18 | 0 | ✅ |
| **Total** | **57** | **57** | **0** | **✅ 100%** |

### 7.2 Análisis Estático

```
Comando: dart analyze
Resultado: No issues found! ✅
```

### 7.3 Pruebas Pendientes (requieren dispositivo físico)

| Tipo | Estado | Requisito |
|---|---|---|
| Pruebas de integración con hardware | ⏳ Pendiente | Dispositivo Android físico |
| Pruebas de reconocimiento de voz real | ⏳ Pendiente | Micrófono funcional |
| Pruebas de usabilidad con usuarios | ⏳ Pendiente | 3-5 usuarios de prueba |
| Pruebas de seguridad de permisos | ⏳ Pendiente | Dispositivo Android 13+ |

---

## Conclusión

Se identificaron y planificaron un total de **96 pruebas** distribuidas en:

| Categoría | Cantidad | Ejecutadas | Pendientes |
|---|---|---|---|
| Pruebas Unitarias | 48 | 57 (con sub-assertions) ✅ | 0 |
| Pruebas de Integración | 14 | 0 | 14 (requieren device) |
| Pruebas de Seguridad/Privacidad | 15 | 3 (análisis estático) | 12 |
| Pruebas de Usabilidad | 27 | 0 | 27 (requieren usuarios) |

Las pruebas unitarias cubren la lógica de negocio más crítica: **modelo de datos**, **gestión de estado** y **comparación de comandos de voz**. Las pruebas de integración, seguridad y usabilidad están planificadas para ejecutarse en dispositivo físico con usuarios reales.
