---
pdf_options:
  format: A4
  margin:
    top: 20mm
    bottom: 20mm
    left: 15mm
    right: 15mm
---

# NutriExercise — Manual de Usuario

Guía práctica para operar el portal web de NutriExercise: filosofía de la
interfaz, Laboratorio RAG (Prompt Lab) y Planificador Semanal de rutinas.

---

## 1. Filosofía del sistema: interfaz "Editorial Tech"

El portal web de NutriExercise sigue el sistema de diseño **Editorial Tech**,
pensado para leer datos como titulares de revista: tipografía grande,
bloques sólidos y contraste alto sobre fondo oscuro.

### 1.1. Navegación

- La **barra lateral** (izquierda) contiene las secciones: **History**,
  **Analytics**, **Routines**, **Nutrition**, **Schedule** y **Profile**.
- La entrada **Routines** abre el Planificador Semanal (`/routine-board`).
- El laboratorio RAG vive en la ruta `/rag-lab` (Prompt Lab).
- La ruta raíz redirige a `/history`.

### 1.2. Contraste alto y bloques sólidos

- Fondo oscuro (`#0f172a`) con superficies (`#1e293b`) y bordes duros y
  visibles; sin sombras suaves.
- El color primario (azul) marca la selección activa y el color de acento
  (naranja) resalta etiquetas importantes como el día asignado o el diálogo
  de duplicado.

### 1.3. Tipografía

- Familia **Montserrat** en toda la aplicación.
- Las etiquetas pequeñas en mayúsculas con espaciado amplio (por ejemplo,
  `SYSTEM PROMPT`, `TEMPERATURE`, `LUNES`) indican controles y metadatos.
- Los números clave (conteo de ejercicios, latencia en ms) se muestran en
  tamaño grande para lectura rápida.

---

## 2. Laboratorio RAG (Prompt Lab)

El Prompt Lab (`/rag-lab`) permite probar consultas contra la base de
conocimiento antes de usarlas en producción. Consta de un panel de
controles (izquierda) y un panel de resultados (derecha).

### 2.1. System Prompt

- Cuadro de texto multilínea donde se define el rol del modelo, por ejemplo:
  `You are a sports nutrition expert…`.
- Cada pulsación actualiza el estado de forma reactiva (sin botón de
  guardado intermedio).
- El texto se envía tal cual junto con la consulta al pulsar **Run Query**.

### 2.2. Temperature

- Deslizador de **0 a 2** en pasos de **0.1** (valor por defecto: **0.7**).
- Valores bajos → respuestas más deterministas y conservadoras.
- Valores altos → respuestas más variadas y creativas.
- El valor numérico se muestra junto al deslizador.

### 2.3. Similarity Threshold (umbral de similitud)

- Deslizador de **0 a 1** en pasos de **0.05** (valor por defecto: **0.8**).
- Filtra las fuentes recuperadas: solo los documentos con puntuación igual
  o superior al umbral aparecen en la tabla de fuentes coincidentes.
- Súbalo para exigir mayor relevancia; bájelo para explorar más contexto.

### 2.4. Test Query y ejecución

1. Escriba la consulta en **Test Query** (por ejemplo:
   `Recovery routine after intense dance rehearsal`).
2. Pulse **Run Query**. El botón se desactiva mientras se procesa y no hace
   nada si la consulta está vacía.
3. Durante la espera aparece el estado `Processing…`.
4. Al terminar verá:
   - **Latency**: tiempo de respuesta en milisegundos y velocidad en
     tokens/segundo.
   - **Generated Answer**: la respuesta generada por el modelo.
   - **Matched Sources**: tabla con título y puntuación (%) de cada fuente,
     ordenada de mayor a menor relevancia.
5. Si algo falla, aparece un mensaje de error
   (`Could not execute the prompt query.`).

### 2.5. Botón Reset y persistencia ("Save Config")

- El botón **Reset** restaura los valores por defecto
  (Temperature **0.7**, Similarity Threshold **0.8**), vacía los campos de
  texto y elimina el resultado y el error.
- **Nota importante:** la versión actual **no incluye botón "Save Config"**
  ni persistencia en `LocalStorage`. La configuración del laboratorio vive
  únicamente en el estado de la sesión: al recargar la página se pierden los
  valores ajustados. Si necesita conservar una configuración, anótela antes
  de pulsar Reset o recargar.

---

## 3. Planificador Semanal (Weekly Planner)

El Planificador (`/routine-board`, entrada **Routines** del menú) es un
tablero estilo Trello donde cada columna es una rutina asignada a un día de
la semana y cada tarjeta es un ejercicio.

### 3.1. Crear rutinas y ejercicios

- El formulario superior permite añadir un ejercicio nuevo: escriba el
  **nombre** (por ejemplo, `Hip Thrust`), elija el **grupo muscular** en el
  desplegable y pulse **Add exercise**.
- El ejercicio se guarda en el catálogo genérico y aparece en la columna
  correspondiente a su grupo muscular.
- Arrastre tarjetas **dentro de una columna** para reordenarlas y **entre
  columnas** para moverlas de rutina.

### 3.2. Etiquetar con Body Zones (zonas del cuerpo)

- Cada columna muestra sus **Body Zones** como insignias en mayúsculas
  (por ejemplo, `LEGS`, `CORE`). Si no tiene ninguna, verá `No body zones`.
- Para añadir una zona: escriba el nombre en el campo **Body zone**
  (por ejemplo, `Legs`) y pulse **Add**.
- Las zonas se normalizan solas: se ignoran los espacios sobrantes y los
  duplicados (`Legs`, ` legs ` y `LEGS` cuentan como una sola).
- Las zonas viajan con la rutina al duplicarla (ver 3.4).

### 3.3. Asignar columnas a días de la semana

- La cabecera de cada columna muestra su **día asignado** en color de
  acento (por ejemplo, `MONDAY`).
- Para cambiarlo, use el **desplegable de día** de la columna y elija otro
  (Monday–Sunday). La columna pasa inmediatamente al carril de ese día.
- La **carrilera de días** bajo el título (`All, Monday, Tuesday, …`)
  filtra el tablero: pulse un día para ver solo sus rutinas, o `All` para
  verlas todas. Si un día no tiene rutinas, verá el mensaje
  `No routines scheduled for this day.`

### 3.4. Función Duplicate (duplicar en varios días)

Sirve para repetir una rutina —por ejemplo, una rutina de recuperación—
en varios días de ensayo (lunes, miércoles y viernes):

1. Pulse **Duplicate to days…** en el pie de la columna origen.
2. Se abre un panel de selección: marque los días destino
   (por ejemplo, `Monday`, `Wednesday`, `Friday`).
3. Pulse **Confirm** (o **Cancel** para abortar).
4. Se crea una copia por cada día elegido con los **mismos ejercicios** y
   las **mismas Body Zones**. El día propio de la columna origen se omite
   automáticamente y no se crean duplicados si repite la operación.

### 3.5. Edición y borrado

- **Renombrar:** haga doble clic en el nombre o pulse **Edit**, edite el
  texto y pulse **Save** (o **Cancel**). El cambio se guarda en el catálogo.
- **Borrado múltiple:** marque las casillas de las tarjetas; aparece el
  botón **Delete selected (N)** en la cabecera. Púlselo para eliminarlas
  del tablero y del catálogo.

---

## 4. Resolución de problemas

| Síntoma | Qué hacer |
|---|---|
| El tablero muestra `Could not load routine board.` | Revise la conexión con el backend o active los mocks de desarrollo. |
| El Prompt Lab muestra `Could not execute the prompt query.` | Compruebe el backend RAG y vuelva a pulsar **Run Query**. |
| **Run Query** no responde | Verifique que **Test Query** no esté vacío; el botón se desactiva sin consulta o durante la carga. |
| Un día aparece vacío | Es normal si no hay rutinas asignadas; use `All` para ver el tablero completo. |
| Se perdió la configuración del Prompt Lab | Es el comportamiento actual: no hay persistencia; reintrodúzcala manualmente. |

---

*Manual generado automáticamente desde `docs/USER_MANUAL.md`*
*(portal web NutriExercise, Angular 22).*
