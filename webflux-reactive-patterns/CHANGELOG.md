# Changelog - WebFlux Reactive Patterns Skill

## Version 1.1 (2026-03-12)

### Mejoras Principales

#### 1. Description Mejorada (Mejor Triggering)
- Descripción más "pushy" para evitar undertriggering
- Casos de uso más explícitos: debugging, refactoring, code review
- Mención explícita de keywords: Mono, Flux, WebFlux, reactive streams

#### 2. Nuevo Archivo: TROUBLESHOOTING.md
Guía completa de troubleshooting con 8 problemas comunes:
- Stream not executing (falta subscribe)
- Blocking calls en código reactivo
- Memory leaks por subscriptions
- Lost context en operaciones paralelas
- Infinite loops/retries
- Errores silenciosos
- Selección incorrecta de operadores
- Timeouts no configurados

Incluye:
- Síntomas de cada problema
- Causa raíz
- Ejemplos de código incorrecto vs correcto
- Técnicas de debugging (logging operators, checkpoint, BlockHound)

#### 3. Decision Tree para Operadores
Agregado al SKILL.md principal:
- Árbol de decisión simple para elegir el operador correcto
- Preguntas guía: ¿Es síncrono? ¿Retorna Mono/Flux?
- Quick reference mejorado

#### 4. Ejemplo Mejorado (reactive-service-example.java)
Nuevos patrones demostrados:
- Timeout handling con `timeout()`
- Retry logic con exponential backoff
- Error recovery con `onErrorResume()`
- Audit logging sin fallar el flujo principal
- Constantes para configuración (OPERATION_TIMEOUT, MAX_RETRY_ATTEMPTS)

#### 5. README Actualizado
- Nueva sección de troubleshooting
- Features expandidos (timeout, retry, error recovery)
- Estructura actualizada con TROUBLESHOOTING.md
- Versión actualizada a 1.1

### Archivos Modificados
- `SKILL.md` - Description mejorada, decision tree, referencia a troubleshooting
- `README.md` - Features y estructura actualizados
- `assets/reactive-service-example.java` - Patrones avanzados agregados

### Archivos Nuevos
- `references/TROUBLESHOOTING.md` - Guía completa de troubleshooting

### Impacto
- **Mejor triggering**: La descripción más explícita hace que el skill se active más consistentemente
- **Más completo**: Cubre casos de uso reales (debugging, performance issues)
- **Más práctico**: Troubleshooting guide ayuda a resolver problemas comunes rápidamente
- **Mejor aprendizaje**: Decision tree simplifica la selección de operadores

---

## Version 1.0 (Original)

### Features Iniciales
- Pure reactive flow patterns
- Lazy error handling con Mono.defer()
- Optional pattern para null checks
- Parallel operations con Mono.zip()
- Helper method extraction
- Code organization best practices
- Pre-implementation analysis workflow

### Archivos Originales
- SKILL.md
- references/BEFORE_CODING.md
- references/REACTIVE_PATTERNS.md
- references/BEST_PRACTICES.md
- assets/reactive-service-example.java
- README.md
