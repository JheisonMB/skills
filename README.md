# Skills - Repositorio de Habilidades para Agentes IA

Este repositorio contiene una colección de habilidades (skills) personalizadas para extender las capacidades de agentes de IA como Claude. Las habilidades son paquetes modulares que proporcionan conocimiento especializado, flujos de trabajo y herramientas específicas de dominio.

## 📋 Contenido

- [Descripción General](#descripción-general)
- [Habilidades Disponibles](#habilidades-disponibles)
- [Instalación](#instalación)
- [Uso](#uso)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Desarrollo](#desarrollo)
- [Contribuir](#contribuir)

## 🎯 Descripción General

Este repositorio funciona como un ecosistema de habilidades que permite a los agentes de IA realizar tareas especializadas con mayor precisión y eficiencia. Cada habilidad está diseñada para un dominio o tarea específica y puede ser instalada y utilizada de forma independiente.

## 🚀 Habilidades Disponibles

### 1. **skill-creator**
Habilidad para crear, modificar y mejorar otras habilidades, además de medir su rendimiento.

**Características:**
- Creación de habilidades desde cero
- Edición y optimización de habilidades existentes
- Ejecución de evaluaciones para probar habilidades
- Análisis de rendimiento con varianza
- Optimización de descripciones para mejor activación

**Cuándo usar:**
- Cuando necesites crear una nueva habilidad
- Para mejorar habilidades existentes
- Para ejecutar benchmarks de rendimiento
- Para optimizar la precisión de activación de habilidades

**Fuente:** `anthropics/skills`

### 2. **find-skills**
Ayuda a descubrir e instalar habilidades del ecosistema abierto de skills.

**Características:**
- Búsqueda de habilidades por palabra clave
- Instalación automática de habilidades
- Verificación de actualizaciones
- Navegación del catálogo en https://skills.sh/

**Cuándo usar:**
- Cuando preguntes "¿cómo hago X?"
- Para buscar funcionalidad específica
- Cuando necesites extender capacidades del agente
- Para explorar herramientas y flujos de trabajo disponibles

**Fuente:** `vercel-labs/skills`

### 3. **webflux-reactive-patterns**
Guía experta para programación reactiva con Java Spring WebFlux.

**Características:**
- Patrones de flujo reactivo puro
- Manejo de errores lazy con `Mono.defer()`
- Uso correcto de `flatMap`, `map`, `filter`
- Operaciones paralelas con `Mono.zip()`
- Eliminación de patrones imperativos

**Cuándo usar:**
- Desarrollo de aplicaciones Spring WebFlux
- Trabajo con tipos Mono y Flux
- Refactorización de código imperativo a reactivo
- Revisión de código reactivo para anti-patrones
- Depuración de problemas reactivos
- Optimización de rendimiento reactivo

**Autor:** jheison.martinez  
**Versión:** 1.1  
**Licencia:** MIT

## 📦 Instalación

### Requisitos Previos
- Node.js y npm instalados
- Kiro CLI o Claude Code

### Instalar Habilidades

Para instalar una habilidad específica, usa el CLI de skills:

```bash
# Buscar habilidades disponibles
npx skills find [consulta]

# Instalar una habilidad
npx skills add <owner/repo@skill>

# Instalar globalmente sin confirmación
npx skills add <owner/repo@skill> -g -y
```

### Instalar desde este Repositorio

```bash
# Clonar el repositorio
git clone <url-del-repositorio>
cd Skills

# Las habilidades están en:
# - .agents/skills/skill-creator/
# - .agents/skills/find-skills/
# - webflux-reactive-patterns/
```

## 💻 Uso

### Activación Automática

Las habilidades se activan automáticamente cuando el agente detecta que tu consulta coincide con la descripción de la habilidad. Por ejemplo:

```
Usuario: "Necesito crear una nueva habilidad para revisar PRs"
→ Se activa: skill-creator

Usuario: "¿Hay alguna habilidad para testing en React?"
→ Se activa: find-skills

Usuario: "Ayúdame a refactorizar este código WebFlux"
→ Se activa: webflux-reactive-patterns
```

### Uso Manual

También puedes referenciar habilidades explícitamente en tus consultas:

```
"Usa la habilidad webflux-reactive-patterns para revisar este código"
```

## 📁 Estructura del Proyecto

```
Skills/
├── .agents/                    # Habilidades instaladas
│   └── skills/
│       ├── skill-creator/      # Creador de habilidades
│       │   ├── SKILL.md
│       │   ├── agents/         # Subagentes especializados
│       │   ├── scripts/        # Scripts de Python
│       │   ├── references/     # Documentación
│       │   └── assets/         # Recursos
│       └── find-skills/        # Buscador de habilidades
│           └── SKILL.md
├── .kiro/                      # Configuración de Kiro
│   ├── settings/
│   │   └── lsp.json           # Configuración LSP
│   └── skills/                 # Enlaces simbólicos a skills
├── webflux-reactive-patterns/  # Habilidad de WebFlux
│   ├── SKILL.md
│   ├── references/             # Patrones y mejores prácticas
│   ├── assets/                 # Ejemplos de código
│   ├── README.md
│   ├── CHANGELOG.md
│   └── LICENSE
└── skills-lock.json            # Registro de habilidades instaladas
```

### Anatomía de una Habilidad

Cada habilidad sigue esta estructura:

```
skill-name/
├── SKILL.md                    # Archivo principal (requerido)
│   ├── Frontmatter YAML        # Metadatos (name, description)
│   └── Contenido Markdown      # Instrucciones
└── Recursos Opcionales
    ├── scripts/                # Código ejecutable
    ├── references/             # Documentación adicional
    └── assets/                 # Archivos de salida (templates, etc.)
```

## 🛠️ Desarrollo

### Crear una Nueva Habilidad

1. **Usar skill-creator:**
   ```
   "Quiero crear una habilidad para [descripción]"
   ```

2. **Manualmente:**
   ```bash
   npx skills init mi-nueva-habilidad
   ```

3. **Estructura básica de SKILL.md:**
   ```markdown
   ---
   name: mi-habilidad
   description: Descripción de cuándo y cómo usar esta habilidad
   ---

   # Mi Habilidad

   ## Cuándo Usar Esta Habilidad
   - Caso de uso 1
   - Caso de uso 2

   ## Instrucciones
   [Contenido de la habilidad]
   ```

### Mejores Prácticas

1. **Descripciones claras:** La descripción debe incluir tanto QUÉ hace la habilidad como CUÁNDO usarla
2. **Divulgación progresiva:** Mantén SKILL.md bajo 500 líneas, usa referencias para contenido extenso
3. **Ejemplos concretos:** Incluye ejemplos prácticos y casos de uso
4. **Patrones imperativos:** Usa forma imperativa en las instrucciones
5. **Sin sorpresas:** El contenido debe ser transparente y seguro

### Probar una Habilidad

```bash
# Ejecutar evaluaciones
python -m scripts.run_eval --skill-path ./mi-habilidad

# Ver resultados
python -m scripts.generate_report ./workspace/iteration-1
```

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para contribuir:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-habilidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva habilidad'`)
4. Push a la rama (`git push origin feature/nueva-habilidad`)
5. Abre un Pull Request

### Lineamientos

- Sigue la estructura estándar de habilidades
- Incluye documentación clara en español
- Agrega ejemplos de uso
- Prueba la habilidad antes de enviar PR
- Actualiza el README si es necesario

## 📚 Recursos Adicionales

- **Skills CLI:** https://skills.sh/
- **Documentación de Kiro:** Ejecuta `kiro-cli --help`
- **Ejemplos de habilidades:** Explora `.agents/skills/` para ver ejemplos

## 📄 Licencias

- **skill-creator:** Licencia según anthropics/skills
- **find-skills:** Licencia según vercel-labs/skills  
- **webflux-reactive-patterns:** MIT License

## 🔄 Actualizaciones

Para actualizar las habilidades instaladas:

```bash
# Verificar actualizaciones disponibles
npx skills check

# Actualizar todas las habilidades
npx skills update
```

## 📞 Soporte

Si encuentras problemas o tienes preguntas:

1. Revisa la documentación de cada habilidad en su `SKILL.md`
2. Consulta los archivos de referencia en `references/`
3. Abre un issue en el repositorio

---

**Última actualización:** 2026-03-12  
**Mantenedor:** jheison.martinez
