// --- Robustez frente a ruido en movimientos ---
// Evitar falsos SR priorizando movimientos más amplios
// Ajuste por defecto alineado con SupportResistance.mqh

//+------------------------------------------------------------------+
//|                                    SupportResistance_v4.mqh      |
//|                        Sistema SR Completamente Reorganizado     |
//|                     Detección por Movimiento y Cambio de Tendencia|
//+------------------------------------------------------------------+
#property copyright "Support & Resistance v4.0 - Sistema Reorganizado"
#property link      ""
#property version   "4.00"

#ifndef SUPPORTRESISTANCE_V4_MQH
#define SUPPORTRESISTANCE_V4_MQH

//+------------------------------------------------------------------+
//| DEFINICIONES Y CONSTANTES                                        |
#define SR_LOCK_DURATION   (48*60*60)   // 48 h en segundos
//+------------------------------------------------------------------+
#define MAX_SR_LEVELS 300            // Aumentado para más niveles
#define MIN_MOVEMENT_BARS 7         // Mínimo de velas para movimiento
#define MAX_MOVEMENT_BARS 30         // Máximo de velas para movimiento
#define TOUCH_CONFIRMATION_BARS 50   // Velas para buscar confirmación
#define INVALIDATION_CANDLES 7
#define INVALIDATION_GRACE_BARS 3  // Barras de gracia antes de evaluar invalidación en niveles nuevos       // Velas consecutivas para invalidar
#define STRENGTH_INCREMENT 1.5       // Incremento de fuerza por toque

// Forward declaration
struct TouchContext;

#ifndef TREND_DIRECTION_ENUM_DEFINED
#define TREND_DIRECTION_ENUM_DEFINED
enum ENUM_TREND_DIRECTION {
   TREND_NONE = 0,
   TREND_UP,
   TREND_DOWN,
   MARKET_BREAKOUT
};
#endif

//+------------------------------------------------------------------+
//| ENUMERACIONES                                                    |
//+------------------------------------------------------------------+
enum ENUM_SR_TYPE {
   SR_SUPPORT,
   SR_RESISTANCE
};

enum ENUM_SR_QUALITY {
   SR_QUALITY_WEAK,
   SR_QUALITY_NORMAL,
   SR_QUALITY_STRONG,
   SR_QUALITY_CRITICAL,
   SR_QUALITY_EXTREME     // NUEVO: Para niveles con muchos toques
};

enum ENUM_SR_STATE {
   SR_STATE_INITIAL,      // Marcado con "1", esperando confirmación
   SR_STATE_CONFIRMED,    // Confirmado con retoque
   SR_STATE_VALIDATED,    // Validado con múltiples toques
   SR_STATE_BROKEN        // Roto
};

enum ENUM_MOVEMENT_TYPE {
   MOVEMENT_NONE,
   MOVEMENT_BULLISH,      // Movimiento alcista fuerte
   MOVEMENT_BEARISH,      // Movimiento bajista fuerte
   MOVEMENT_IMPULSE,      // Impulso muy fuerte
   MOVEMENT_CORRECTIVE    // Movimiento correctivo
};

//+------------------------------------------------------------------+
//| ESTRUCTURA MovementData - Para análisis de movimientos          |
//+------------------------------------------------------------------+
struct MovementData {
   ENUM_MOVEMENT_TYPE type;          // Tipo de movimiento
   double             startPrice;    // Precio inicial
   double             endPrice;      // Precio final
   datetime           startTime;     // Tiempo inicial
   datetime           endTime;       // Tiempo final
   int                barCount;      // Número de velas
   double             avgBarSize;    // Tamaño promedio de vela
   double             totalSize;     // Tamaño total del movimiento
   double             velocity;      // Velocidad (puntos/barra)
   double             strength;      // Fuerza del movimiento
   bool               completed;     // Si el movimiento está completo
   int                turningBar;    // Barra donde cambió la tendencia
   double             turningPrice;  // Precio del punto de giro
   double             lastBarSize;   // Tamaño de la última vela antes del giro
};

//+------------------------------------------------------------------+
//| ESTRUCTURA PRINCIPAL SRLevel v4                                 |
//+------------------------------------------------------------------+
struct SRLevel {
   int                       id;
   double                    price;              // Precio exacto del nivel
   double                    zoneHigh;           // Zona superior
   double                    zoneLow;            // Zona inferior
   ENUM_SR_TYPE             type;               // Soporte o Resistencia
   ENUM_TIMEFRAMES          sourceTimeframe;    // Timeframe de origen
   ENUM_SR_STATE            state;              // Estado del nivel
   datetime                 creationTime;       // Cuando se creó
   int                      touchCount;         // Número de toques confirmados
   int                      initialMark;        // Marca inicial (1)
   datetime                 firstTouchTime;     // Primer toque
   datetime                 lastTouchTime;      // Último toque
   datetime                 confirmationTime;   // Cuando se confirmó
   double                   strength;           // Fuerza del nivel
   ENUM_SR_QUALITY          quality;            // Calidad
   bool                     active;             // Activo
   int                      consecutiveBreaks;  // Rupturas consecutivas
   bool                     isVisible;          // Visible en gráfico
   string                   objectName;         // Nombre del objeto gráfico
   
   // NUEVO: Datos del movimiento original
   MovementData             originalMovement;   // Movimiento que generó el nivel
   double                   initialZoneSize;    // Tamaño inicial de la zona
   double                   currentZoneSize;    // Tamaño actual de la zona
   
   // NUEVO: Historial de toques
   datetime                 touchTimes[20];     // Tiempos de toques
   double                   touchPrices[20];    // Precios de toques
   int                      touchStrengths[20]; // Fuerza de cada toque
   
   // Estadísticas mejoradas
   int                      successfulBounces;  // Rebotes exitosos
   int                      failedBreaks;       // Rupturas falsas
   double                   avgBounceSize;      // Tamaño promedio de rebote
   double                   maxBounceSize;      // Máximo rebote
   double                   totalBounceVolume;  // Volumen total en rebotes
   
   // NUEVO: Información visual
   int                      lineWidth;          // Ancho de línea (1-5)
   color                    lineColor;          // Color dinámico
   bool                     showLabel;          // Mostrar etiqueta
   string                   labelText;          // Texto de la etiqueta
    bool                     locked;           // Bloqueado tras ruptura
    datetime                 lock_time;        // Momento de bloqueo
};

//+------------------------------------------------------------------+
//| TouchContext para comunicación con TradingStrategy              |
//+------------------------------------------------------------------+
struct TouchContext {
    bool                     valid;
    double                   price;
    datetime                 time;
    SRLevel                  level;
    double                   quality;         // 0-1 normalizado
    string                   reason;
    ENUM_TIMEFRAMES         detectedTimeframe;
    double                   distanceToLevel;
    bool                     isFirstTouch;
    double                   levelStrength;   // NUEVO: Fuerza específica del nivel
    int                      touchNumber;     // NUEVO: Número de toque
};

//+------------------------------------------------------------------+
//| CLASE PRINCIPAL CSupportResistance v4                           |
//+------------------------------------------------------------------+
class CSupportResistance {
private:
    // Configuración
    bool                     m_showVisual;
    bool                     m_initialized;
    string                   m_prefix;
    
    // Timeframes configurables
    ENUM_TIMEFRAMES          m_timeframes[4];    // M30, H1, H4, D1
    bool                     m_tfEnabled[4];      // Cuáles están activos
    
    // Almacenamiento de niveles
    SRLevel                  m_levels[MAX_SR_LEVELS];
    int                      m_levelCount;
    
    // NUEVO: Tracking de movimientos
    MovementData             m_currentMovements[4]; // Un movimiento por TF
    bool                     m_trackingMovement[4]; // Si estamos tracking
    
    // Control interno
    datetime                 m_lastUpdate;
    
    datetime                 m_lastTFBar[4];   // Última barra procesada por TF (PER-TF throttle)
double                   m_minMovementSize;   // Tamaño mínimo de movimiento
    double                   m_dynamicBarCount;   // Número dinámico de barras
    int                      m_confirmationBars;  // Barras para confirmación
    
    // Cache de precios
    double                   m_currentBid;
    double                   m_currentAsk;
    double                   m_currentATR;
    
    // NUEVO: Parámetros dinámicos
    double                   m_volatilityFactor;  // Factor de volatilidad actual
    double                   m_trendStrength;     // Fuerza de tendencia
    
    // Métodos privados de gestión
    void                     InitializeArrays();
    void                     CleanupGraphics();
    void                     CreateLevelObject(SRLevel &level);
    void                     UpdateLevelObject(SRLevel &level);
    void                     RemoveLevelObject(SRLevel &level);
    string                   GenerateObjectName(int id, ENUM_TIMEFRAMES tf);
    
    // NUEVO: Métodos de detección de movimientos
    bool                     DetectSignificantMovements(ENUM_TIMEFRAMES tf);
    bool                     AnalyzeMovement(const MqlRates &rates[], int startBar, int endBar, 
                                           MovementData &movement, ENUM_TIMEFRAMES tf);
    bool                     DetectTrendChange(const MqlRates &rates[], int currentBar, 
                                             ENUM_MOVEMENT_TYPE prevType);
    double                   CalculateDynamicBars(ENUM_TIMEFRAMES tf, double avgBarSize);
    bool                     IsMovementSignificant(const MovementData &movement, ENUM_TIMEFRAMES tf);
    
    // NUEVO: Métodos de confirmación
    bool                     CreateInitialLevel(const MovementData &movement, ENUM_TIMEFRAMES tf);
    bool                     CheckLevelConfirmation(int levelIndex);
    bool                     UpgradeLevelStrength(int levelIndex);
    void                     RecordTouch(int levelIndex, double touchPrice, datetime touchTime);
    
    // Métodos de validación mejorados
    bool                     CheckConsecutiveBreaks(SRLevel &level);
    void                     InvalidateLevel(int levelIndex);
    bool                     IsNearExistingLevel(double price, ENUM_TIMEFRAMES tf, double tolerance);
    int                      FindNearestLevel(double price, ENUM_SR_TYPE type, ENUM_TIMEFRAMES tf);
    
    // Métodos de limpieza
    void                     CleanupOldLevels();
    void                     ConsolidateLevels();
    void                     RemoveWeakLevels();
    
    // NUEVO: Métodos de visualización mejorada
    void                     UpdateLevelVisuals(int levelIndex);
    color                    GetDynamicColor(const SRLevel &level);
    int                      GetDynamicWidth(const SRLevel &level);
    void                     CreateLevelLabel(SRLevel &level);
    void                     UpdateLevelLabel(SRLevel &level);
    
    // Utilidades
    double                   GetATRForTimeframe(ENUM_TIMEFRAMES tf, int period = 14);
    double                   CalculateZoneSize(ENUM_TIMEFRAMES tf, double barSize);
    double                   GetVolatilityMultiplier(ENUM_TIMEFRAMES tf);
    void                     UpdateMarketContext();
    
public:
    // Métodos auxiliares
    int                      GetTimeframeIndex(ENUM_TIMEFRAMES tf);
    string                   GetStateString(ENUM_SR_STATE state);
    string                   GetQualityString(ENUM_SR_QUALITY quality);
    string                   GetMovementTypeString(ENUM_MOVEMENT_TYPE type);

    // Constructor y destructor
                            CSupportResistance();
                           ~CSupportResistance();
    
    // Inicialización
    bool                     Init(bool showVisual = true);
    bool                     ConfigureTimeframes(bool useM30, bool useH1, bool useH4, bool useD1);
    void                     SetParameters(double minMovementATR = 2.0, int confirmBars = 50);
    
    // MÉTODOS PRINCIPALES v4
    int                      UpdateLevels();                          // Actualizar todos los niveles
    bool                     DetectSRTouch(TouchContext &touchContext); // Detectar toque actual
    bool                     GetNearestLevel(double price, SRLevel &level, ENUM_SR_TYPE preferredType = SR_SUPPORT);
    
    // NUEVO: Métodos de consulta mejorados
    int                      GetStrongLevels(SRLevel &levels[], double minStrength = 5.0);
    int                      GetConfirmedLevels(SRLevel &levels[], ENUM_SR_STATE minState = SR_STATE_CONFIRMED);
    bool                     GetLevelDetails(int levelId, SRLevel &level);
    double                   GetNearestSupportPrice(double currentPrice);
    double                   GetNearestResistancePrice(double currentPrice);
    
    // Gestión de niveles
    void                     CheckInvalidations();
    void                     UpdateTouchCounts();
    int                      GetActiveLevelCount() { return m_levelCount; }
    
    // Acceso a niveles
    bool                     GetLevelByIndex(int index, SRLevel &level);
    int                      GetLevelsInRange(double priceFrom, double priceTo, SRLevel &levels[]);
    
    // Votación mejorada
    ENUM_TREND_DIRECTION     GetVoteDirection(double &confidence);
    double                   GetLevelImportance(const SRLevel &level); // NUEVO
    
    // Visualización
    void                     ForceVisualUpdate();
    void                     ShowTimeframeFilter(ENUM_TIMEFRAMES tf);
    void                     HideTimeframeFilter(ENUM_TIMEFRAMES tf);
    void                     ShowStrongLevelsOnly(double minStrength = 5.0);
    
    // Debug y estadísticas
    void                     PrintStatistics();
    void                     PrintNearbyLevels(double price, double range);
    void                     PrintMovementAnalysis();  // NUEVO
    void                     PrintLevelDetails(int levelId); // NUEVO
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSupportResistance::CSupportResistance() {
    m_showVisual = true;
    m_initialized = false;
    m_levelCount = 0;
    m_lastUpdate = 0;
    m_minMovementSize = 0.0;
    m_dynamicBarCount = 20;
    m_confirmationBars = TOUCH_CONFIRMATION_BARS;
    m_currentATR = 0.0;
    m_volatilityFactor = 1.0;
    m_trendStrength = 0.0;
    m_prefix = "SR_v4_" + IntegerToString(GetTickCount()) + "_";
    
    // Configurar timeframes por defecto
    m_timeframes[0] = PERIOD_M30;
    m_timeframes[1] = PERIOD_H1;
    m_timeframes[2] = PERIOD_H4;
    m_timeframes[3] = PERIOD_D1;
    
    // Todos habilitados
    for(int i=0;i<4;i++) m_lastTFBar[i]=0; // init per-TF last bar por defecto
    for(int i = 0; i < 4; i++) {
        m_tfEnabled[i] = true;
        m_trackingMovement[i] = false;
    }
    
    InitializeArrays();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSupportResistance::~CSupportResistance() {
    CleanupGraphics();
}

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
bool CSupportResistance::Init(bool showVisual) {
    m_showVisual = showVisual;
    
    // Limpiar todo
    InitializeArrays();
    CleanupGraphics();
    
    // Actualizar contexto inicial
    UpdateMarketContext();
    
    m_initialized = true;
    
    Print("=== SupportResistance v4.0 Inicializado ===");
    Print("Sistema reorganizado con detección por movimiento y cambio de tendencia");
    Print("Niveles máximos: ", MAX_SR_LEVELS);
    Print("Detección dinámica de movimientos: ACTIVADA");
    Print("Confirmación por retoque: ACTIVADA");
    Print("Fortalecimiento progresivo: ACTIVADO");
    
    return true;
}

//+------------------------------------------------------------------+
//| ACTUALIZAR NIVELES - Método principal v4                        |
//+------------------------------------------------------------------+
int CSupportResistance::UpdateLevels() {
    if(!m_initialized) return 0;
    
    // Actualizar contexto de mercado
    UpdateMarketContext();
    
    // Actualizar precios actuales
    m_currentBid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    m_currentAsk = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    
    // Para cada timeframe configurado
    for(int tf = 0; tf < 4; tf++) {
        if(!m_tfEnabled[tf]) continue;
        
        
        datetime __tfBar = iTime(Symbol(), m_timeframes[tf], 0);
        if(__tfBar == m_lastTFBar[tf]) continue; // skip until new bar on this TF
        m_lastTFBar[tf] = __tfBar;
// 1. Detectar nuevos movimientos significativos
        DetectSignificantMovements(m_timeframes[tf]);
        
        // 2. Verificar confirmaciones de niveles iniciales
        for(int i = 0; i < MAX_SR_LEVELS; i++) {
            if(m_levels[i].active && 
               m_levels[i].sourceTimeframe == m_timeframes[tf] &&
               m_levels[i].state == SR_STATE_INITIAL) {
                CheckLevelConfirmation(i);
            }
        }
        
        // 3. Actualizar fuerza de niveles confirmados
        for(int i = 0; i < MAX_SR_LEVELS; i++) {
            if(m_levels[i].active && 
               m_levels[i].sourceTimeframe == m_timeframes[tf] &&
               m_levels[i].state >= SR_STATE_CONFIRMED) {
                UpgradeLevelStrength(i);
            }
        }
    }
    
    // Verificar invalidaciones
    CheckInvalidations();
    
    // Actualizar contadores de toques
    UpdateTouchCounts();
    
    // Consolidar niveles cercanos
    if(m_levelCount > MAX_SR_LEVELS * 0.7) {
        ConsolidateLevels();
    }
    
    // Limpiar niveles débiles o antiguos
    if(m_levelCount > MAX_SR_LEVELS * 0.8) {
        CleanupOldLevels();
        RemoveWeakLevels();
    }
    
    // Actualizar visualización
    if(m_showVisual) {
        ForceVisualUpdate();
    }
    
    m_lastUpdate = TimeCurrent();
    
    return m_levelCount;
}

//+------------------------------------------------------------------+
//| DETECTAR MOVIMIENTOS SIGNIFICATIVOS                             |
//+------------------------------------------------------------------+
bool CSupportResistance::DetectSignificantMovements(ENUM_TIMEFRAMES tf) {
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Obtener suficientes barras para análisis
    int barsNeeded = 200;
    int copied = CopyRates(Symbol(), tf, 0, barsNeeded, rates);
    
    if(copied < 50) return false;
    
    // Calcular tamaño promedio de velas
    double totalBarSize = 0;
    for(int i = 0; i < 50; i++) {
        totalBarSize += rates[i].high - rates[i].low;
    }
    double avgBarSize = totalBarSize / 50;
    
    // Calcular número dinámico de barras para movimiento
    m_dynamicBarCount = CalculateDynamicBars(tf, avgBarSize);
    
    // Si ya estamos rastreando un movimiento
    int tfIndex = GetTimeframeIndex(tf);
    if(m_trackingMovement[tfIndex]) {
        // Verificar si el movimiento actual terminó
        // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: current

        
        // Buscar cambio de tendencia
        if(DetectTrendChange(rates, 0, m_currentMovements[tfIndex].type)) {
            // Movimiento completado, crear nivel inicial
            m_currentMovements[tfIndex].completed = true;
            m_currentMovements[tfIndex].turningBar = 0;
            m_currentMovements[tfIndex].turningPrice = rates[0].close;
            m_currentMovements[tfIndex].lastBarSize = rates[0].high - rates[0].low;
            
            if(CreateInitialLevel(m_currentMovements[tfIndex], tf)) {
                Print("Nivel inicial creado en ", EnumToString(tf), 
                      " @ ", DoubleToString(m_currentMovements[tfIndex].turningPrice, _Digits));
            }
            
            m_trackingMovement[tfIndex] = false;
        }
    }
    
    // Buscar nuevos movimientos
    for(int i = 10; i < copied - 30; i++) {
        MovementData movement;
        
        // Intentar detectar movimiento alcista
        if(AnalyzeMovement(rates, i + (int)m_dynamicBarCount, i, movement, tf)) {
            if(IsMovementSignificant(movement, tf)) {
                // Verificar si hay cambio de tendencia después
                bool trendChanged = false;
                for(int j = i - 1; j >= 0 && j >= i - 10; j--) {
                    if(DetectTrendChange(rates, j, movement.type)) {
                        movement.completed = true;
                        movement.turningBar = j;
                        movement.turningPrice = (movement.type == MOVEMENT_BULLISH) ? 
                                               rates[j].high : rates[j].low;
                        movement.lastBarSize = rates[j].high - rates[j].low;
                        
                        // Crear nivel inicial
                        if(CreateInitialLevel(movement, tf)) {
                            Print("Nuevo movimiento detectado y nivel creado");
                        }
                        
                        trendChanged = true;
                        break;
                    }
                }
                
                // Si no hay cambio aún, empezar a rastrear
                if(!trendChanged && !m_trackingMovement[tfIndex]) {
                    m_currentMovements[tfIndex] = movement;
                    m_trackingMovement[tfIndex] = true;
                }
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| ANALIZAR MOVIMIENTO                                             |
//+------------------------------------------------------------------+
bool CSupportResistance::AnalyzeMovement(const MqlRates &rates[], int startBar, int endBar, 
                                        MovementData &movement, ENUM_TIMEFRAMES tf) {
    if(startBar <= endBar || startBar >= ArraySize(rates) || endBar < 0) return false;
    
    // Inicializar estructura
    movement.startPrice = rates[startBar].close;
    movement.endPrice = rates[endBar].close;
    movement.startTime = rates[startBar].time;
    movement.endTime = rates[endBar].time;
    movement.barCount = startBar - endBar;
    movement.completed = false;
    
    // Determinar tipo de movimiento
    double priceChange = movement.endPrice - movement.startPrice;
    movement.totalSize = MathAbs(priceChange);
    
    if(priceChange > 0) {
        movement.type = MOVEMENT_BULLISH;
    } else if(priceChange < 0) {
        movement.type = MOVEMENT_BEARISH;
    } else {
        movement.type = MOVEMENT_NONE;
        return false;
    }
    
    // Calcular estadísticas del movimiento
    double totalBarSize = 0;
    int bullishBars = 0;
    int bearishBars = 0;
    
    for(int i = startBar; i > endBar; i--) {
        double barSize = rates[i].high - rates[i].low;
        totalBarSize += barSize;
        
        if(rates[i].close > rates[i].open) bullishBars++;
        else bearishBars++;
    }
    
    movement.avgBarSize = totalBarSize / movement.barCount;
    movement.velocity = movement.totalSize / movement.barCount;
    
    // Calcular fuerza del movimiento
    double directionRatio = 0;
    if(movement.type == MOVEMENT_BULLISH) {
        directionRatio = (double)bullishBars / movement.barCount;
    } else {
        directionRatio = (double)bearishBars / movement.barCount;
    }
    
    // Fuerza basada en velocidad, consistencia y tamaño
    movement.strength = (movement.velocity / m_currentATR) * directionRatio * 
                       (movement.totalSize / (m_currentATR * 2));
    
    // Verificar si es un impulso fuerte
    if(movement.strength > 2.0 && directionRatio > 0.7) {
        movement.type = MOVEMENT_IMPULSE;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| DETECTAR CAMBIO DE TENDENCIA                                    |
//+------------------------------------------------------------------+
bool CSupportResistance::DetectTrendChange(const MqlRates &rates[], int currentBar, 
                                          ENUM_MOVEMENT_TYPE prevType) {
    if(currentBar < 1 || currentBar >= ArraySize(rates) - 1) return false;
    
    // Para movimiento alcista previo, buscar señales bajistas
    if(prevType == MOVEMENT_BULLISH || prevType == MOVEMENT_IMPULSE) {
        // Patrón de reversión bajista
        if(rates[currentBar].high > rates[currentBar+1].high && 
           rates[currentBar].close < rates[currentBar].open &&
           rates[currentBar].close < rates[currentBar+1].close) {
            return true;
        }
        
        // Rotura de mínimos
        if(rates[currentBar].low < rates[currentBar+1].low && 
           rates[currentBar].low < rates[currentBar+2].low) {
            return true;
        }
    }
    // Para movimiento bajista previo, buscar señales alcistas
    else if(prevType == MOVEMENT_BEARISH) {
        // Patrón de reversión alcista
        if(rates[currentBar].low < rates[currentBar+1].low && 
           rates[currentBar].close > rates[currentBar].open &&
           rates[currentBar].close > rates[currentBar+1].close) {
            return true;
        }
        
        // Rotura de máximos
        if(rates[currentBar].high > rates[currentBar+1].high && 
           rates[currentBar].high > rates[currentBar+2].high) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| CALCULAR NÚMERO DINÁMICO DE BARRAS                              |
//+------------------------------------------------------------------+
double CSupportResistance::CalculateDynamicBars(ENUM_TIMEFRAMES tf, double avgBarSize) {
    // Base: 20 barras
    double bars = 20;
    
    // Ajustar por timeframe
    switch(tf) {
        case PERIOD_M30: bars = 25; break;
        case PERIOD_H1:  bars = 20; break;
        case PERIOD_H4:  bars = 15; break;
        case PERIOD_D1:  bars = 12; break;
    }
    
    // Ajustar por volatilidad
    double volatilityRatio = avgBarSize / m_currentATR;
    if(volatilityRatio > 1.5) {
        bars *= 0.8;  // Menos barras si hay mucha volatilidad
    } else if(volatilityRatio < 0.7) {
        bars *= 1.2;  // Más barras si hay poca volatilidad
    }
    
    // Limitar rango
    bars = MathMax(MIN_MOVEMENT_BARS, MathMin(MAX_MOVEMENT_BARS, bars));
    
    return bars;
}

//+------------------------------------------------------------------+
//| VERIFICAR SI MOVIMIENTO ES SIGNIFICATIVO                        |
//+------------------------------------------------------------------+
bool CSupportResistance::IsMovementSignificant(const MovementData &movement, ENUM_TIMEFRAMES tf) {
    // Tamaño mínimo en ATRs
    double minSizeATR = 2.0;
    switch(tf) {
        case PERIOD_M30: minSizeATR = 1.5; break;
        case PERIOD_H1:  minSizeATR = 2.0; break;
        case PERIOD_H4:  minSizeATR = 2.5; break;
        case PERIOD_D1:  minSizeATR = 3.0; break;
    }
    
    if(movement.totalSize < m_currentATR * minSizeATR) return false;
    
    // Velocidad mínima
    if(movement.velocity < m_currentATR * 0.1) return false;
    
    // Fuerza mínima
    if(movement.strength < 0.5) return false;
    
    // Para impulsos, requisitos más estrictos
    if(movement.type == MOVEMENT_IMPULSE && movement.strength < 1.5) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| CREAR NIVEL INICIAL                                             |
//+------------------------------------------------------------------+
bool CSupportResistance::CreateInitialLevel(const MovementData &movement, ENUM_TIMEFRAMES tf) {
    // Verificar si ya existe un nivel cercano
    double tolerance = movement.lastBarSize * 2;
    if(IsNearExistingLevel(movement.turningPrice, tf, tolerance)) {
        // Actualizar el nivel existente
        int nearestIdx = FindNearestLevel(movement.turningPrice, 
                                         (movement.type == MOVEMENT_BULLISH) ? SR_RESISTANCE : SR_SUPPORT, 
                                         tf);
        if(nearestIdx >= 0) {
            m_levels[nearestIdx].touchCount++;
            m_levels[nearestIdx].lastTouchTime = TimeCurrent();
            UpdateLevelVisuals(nearestIdx);
            return false;  // Actualización de nivel existente (no nuevo)
        }
    }
    
    // Buscar espacio libre
    int freeIndex = -1;
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) {
            freeIndex = i;
            break;
        }
    }
    
    if(freeIndex == -1) {
        Print("No hay espacio para nuevos niveles SR");
        return false;
    }
    
    // Crear nuevo nivel
    // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: newLevel

    m_levels[freeIndex].id = freeIndex;
    m_levels[freeIndex].price = NormalizeDouble(movement.turningPrice, _Digits);
    m_levels[freeIndex].type = (movement.type == MOVEMENT_BULLISH) ? SR_RESISTANCE : SR_SUPPORT;
    m_levels[freeIndex].sourceTimeframe = tf;
    m_levels[freeIndex].state = SR_STATE_INITIAL;
    m_levels[freeIndex].creationTime = TimeCurrent();
    m_levels[freeIndex].firstTouchTime = TimeCurrent();
    m_levels[freeIndex].lastTouchTime = TimeCurrent();
    m_levels[freeIndex].confirmationTime = 0;
    m_levels[freeIndex].touchCount = 0;
    m_levels[freeIndex].initialMark = 1;
    m_levels[freeIndex].active = true;
    m_levels[freeIndex].consecutiveBreaks = 0;
    m_levels[freeIndex].isVisible = false;
    m_levels[freeIndex].objectName = "";
    
    // Guardar datos del movimiento
    m_levels[freeIndex].originalMovement = movement;
    
    // Calcular zona inicial basada en la última vela
    m_levels[freeIndex].initialZoneSize = movement.lastBarSize;
    m_levels[freeIndex].currentZoneSize = movement.lastBarSize;
    m_levels[freeIndex].zoneHigh = m_levels[freeIndex].price + (m_levels[freeIndex].currentZoneSize / 2);
    m_levels[freeIndex].zoneLow = m_levels[freeIndex].price - (m_levels[freeIndex].currentZoneSize / 2);
    
    // Calcular fuerza inicial
    m_levels[freeIndex].strength = movement.strength;
    m_levels[freeIndex].quality = SR_QUALITY_WEAK;
    
    // Inicializar arrays
    for(int i = 0; i < 20; i++) {
        m_levels[freeIndex].touchTimes[i] = 0;
        m_levels[freeIndex].touchPrices[i] = 0;
        m_levels[freeIndex].touchStrengths[i] = 0;
    }
    
    // Estadísticas iniciales
    m_levels[freeIndex].successfulBounces = 0;
    m_levels[freeIndex].failedBreaks = 0;
    m_levels[freeIndex].avgBounceSize = 0.0;
    m_levels[freeIndex].maxBounceSize = 0.0;
    m_levels[freeIndex].totalBounceVolume = 0.0;
    
    // Configuración visual inicial
    m_levels[freeIndex].lineWidth = 1;
    m_levels[freeIndex].lineColor = GetDynamicColor(m_levels[freeIndex]);
    m_levels[freeIndex].showLabel = false;
    m_levels[freeIndex].labelText = "1";  // Marca inicial
    
    m_levelCount++;
    
    // Crear objeto visual inicial (delgado)
    if(m_showVisual) {
        CreateLevelObject(m_levels[freeIndex]);
    }
    
    Print("Nivel inicial creado: ", 
          EnumToString(tf), " ",
          (m_levels[freeIndex].type == SR_SUPPORT ? "SOPORTE" : "RESISTENCIA"),
          " @ ", DoubleToString(m_levels[freeIndex].price, _Digits),
          " [Movimiento: ", DoubleToString(movement.totalSize/_Point, 0), " pts]");
    
    return true;
}

//+------------------------------------------------------------------+
//| VERIFICAR CONFIRMACIÓN DE NIVEL                                 |
//+------------------------------------------------------------------+
bool CSupportResistance::CheckLevelConfirmation(int levelIndex) {
    if(levelIndex < 0 || levelIndex >= MAX_SR_LEVELS) return false;
    
    // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: level

    if(!m_levels[levelIndex].active || m_levels[levelIndex].state != SR_STATE_INITIAL) return false;
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Obtener barras desde la creación del nivel
    datetime currentTime = TimeCurrent();
    int barsToCheck = Bars(Symbol(), m_levels[levelIndex].sourceTimeframe, m_levels[levelIndex].creationTime, currentTime);
    
    if(barsToCheck < 2) return false;
    
    int copied = CopyRates(Symbol(), m_levels[levelIndex].sourceTimeframe, 0, 
                          MathMin(barsToCheck, m_confirmationBars), rates);
    
    if(copied < 2) return false;
    
    // Buscar toques en la zona
    for(int i = 1; i < copied; i++) {
        bool touched = false;
        double touchPrice = 0;
        
        // Para soporte
        if(m_levels[levelIndex].type == SR_SUPPORT) {
            if(rates[i].low <= m_levels[levelIndex].zoneHigh && rates[i].low >= m_levels[levelIndex].zoneLow) {
                touched = true;
                touchPrice = rates[i].low;
            }
        }
        // Para resistencia
        else {
            if(rates[i].high >= m_levels[levelIndex].zoneLow && rates[i].high <= m_levels[levelIndex].zoneHigh) {
                touched = true;
                touchPrice = rates[i].high;
            }
        }
        
        if(touched) {
            // Verificar que no sea el mismo movimiento
            if(rates[i].time > m_levels[levelIndex].originalMovement.endTime + PeriodSeconds(m_levels[levelIndex].sourceTimeframe) * 5) {
                // Confirmar nivel
                m_levels[levelIndex].state = SR_STATE_CONFIRMED;
                m_levels[levelIndex].confirmationTime = rates[i].time;
                m_levels[levelIndex].touchCount = 1;
                
                // Registrar el toque
                RecordTouch(levelIndex, touchPrice, rates[i].time);
                
                // Actualizar visuales
                UpdateLevelVisuals(levelIndex);
                
                Print("Nivel CONFIRMADO: ", 
                      EnumToString(m_levels[levelIndex].sourceTimeframe), " ",
                      (m_levels[levelIndex].type == SR_SUPPORT ? "SOPORTE" : "RESISTENCIA"),
                      " @ ", DoubleToString(m_levels[levelIndex].price, _Digits));
                
                return true;
            }
        }
    }
    
    // Si ha pasado mucho tiempo sin confirmación, invalidar
    if(barsToCheck > m_confirmationBars * 2) {
        Print("Nivel no confirmado - invalidando");
        InvalidateLevel(levelIndex);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| MEJORAR FUERZA DEL NIVEL                                        |
//+------------------------------------------------------------------+
bool CSupportResistance::UpgradeLevelStrength(int levelIndex) {
    if(levelIndex < 0 || levelIndex >= MAX_SR_LEVELS) return false;
    
    // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: level

    if(!m_levels[levelIndex].active || m_levels[levelIndex].state < SR_STATE_CONFIRMED) return false;
    
    double currentPrice = (m_levels[levelIndex].type == SR_SUPPORT) ? m_currentBid : m_currentAsk;
    double distance = MathAbs(currentPrice - m_levels[levelIndex].price);
    
    // Si el precio está cerca del nivel
    if(distance <= m_levels[levelIndex].currentZoneSize) {
        // Incrementar fuerza gradualmente
        double oldStrength = m_levels[levelIndex].strength;
        m_levels[levelIndex].strength += STRENGTH_INCREMENT * (1.0 / (m_levels[levelIndex].touchCount + 1));
        
        // Actualizar calidad basada en toques
        if(m_levels[levelIndex].touchCount >= 10 && m_levels[levelIndex].failedBreaks == 0) {
            m_levels[levelIndex].quality = SR_QUALITY_EXTREME;
            m_levels[levelIndex].state = SR_STATE_VALIDATED;
        }
        else if(m_levels[levelIndex].touchCount >= 7) {
            m_levels[levelIndex].quality = SR_QUALITY_CRITICAL;
            m_levels[levelIndex].state = SR_STATE_VALIDATED;
        }
        else if(m_levels[levelIndex].touchCount >= 5) {
            m_levels[levelIndex].quality = SR_QUALITY_STRONG;
        }
        else if(m_levels[levelIndex].touchCount >= 3) {
            m_levels[levelIndex].quality = SR_QUALITY_NORMAL;
        }
        
        // Expandir zona si hay muchos toques
        if(m_levels[levelIndex].touchCount > 5 && m_levels[levelIndex].touchCount % 3 == 0) {
            double expansion = m_levels[levelIndex].initialZoneSize * 0.1;
            m_levels[levelIndex].currentZoneSize += expansion;
            m_levels[levelIndex].zoneHigh = m_levels[levelIndex].price + (m_levels[levelIndex].currentZoneSize / 2);
            m_levels[levelIndex].zoneLow = m_levels[levelIndex].price - (m_levels[levelIndex].currentZoneSize / 2);
        }
        
        // Actualizar visuales si cambió significativamente
        if(m_levels[levelIndex].strength - oldStrength > 0.5) {
            UpdateLevelVisuals(levelIndex);
        }
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| REGISTRAR TOQUE                                                 |
//+------------------------------------------------------------------+
void CSupportResistance::RecordTouch(int levelIndex, double touchPrice, datetime touchTime) {
    if(levelIndex < 0 || levelIndex >= MAX_SR_LEVELS) return;
    
    // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: level

    
    // Buscar espacio en el array
    int touchIdx = -1;
    for(int i = 0; i < 20; i++) {
        if(m_levels[levelIndex].touchTimes[i] == 0) {
            touchIdx = i;
            break;
        }
    }
    
    // Si está lleno, sobrescribir el más antiguo
    if(touchIdx == -1) {
        // Mover todos una posición
        for(int i = 19; i > 0; i--) {
            m_levels[levelIndex].touchTimes[i] = m_levels[levelIndex].touchTimes[i-1];
            m_levels[levelIndex].touchPrices[i] = m_levels[levelIndex].touchPrices[i-1];
            m_levels[levelIndex].touchStrengths[i] = m_levels[levelIndex].touchStrengths[i-1];
        }
        touchIdx = 0;
    }
    
    // Registrar nuevo toque
    m_levels[levelIndex].touchTimes[touchIdx] = touchTime;
    m_levels[levelIndex].touchPrices[touchIdx] = touchPrice;
    m_levels[levelIndex].touchStrengths[touchIdx] = (int)m_levels[levelIndex].strength;
    
    m_levels[levelIndex].lastTouchTime = touchTime;
}

//+------------------------------------------------------------------+
//| ACTUALIZAR CONTADORES DE TOQUES                                 |
//+------------------------------------------------------------------+
void CSupportResistance::UpdateTouchCounts() {
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active || m_levels[i].state < SR_STATE_CONFIRMED) continue;
        
        double distance = MathAbs(m_currentBid - m_levels[i].price);
        
        // Si está en la zona
        if(distance <= m_levels[i].currentZoneSize / 2) {
            datetime timeSinceTouch = TimeCurrent() - m_levels[i].lastTouchTime;
            
            // Evitar contar múltiples toques muy seguidos
            if(timeSinceTouch >= PeriodSeconds(m_levels[i].sourceTimeframe) * 2) {
                m_levels[i].touchCount++;
                m_levels[i].lastTouchTime = TimeCurrent();
                
                // Registrar el toque
                RecordTouch(i, m_currentBid, TimeCurrent());
                
                // Calcular rebote
                if(m_levels[i].type == SR_SUPPORT && m_currentBid > m_levels[i].price) {
                    m_levels[i].successfulBounces++;
                }
                else if(m_levels[i].type == SR_RESISTANCE && m_currentBid < m_levels[i].price) {
                    m_levels[i].successfulBounces++;
                }
                
                // Actualizar fuerza y visuales
                UpgradeLevelStrength(i);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| DETECTAR TOQUE SR                                               |
//+------------------------------------------------------------------+
bool CSupportResistance::DetectSRTouch(TouchContext &touchContext) {
    touchContext.valid = false;

    double currentPrice = m_currentBid;

    // Debounce: procesa solo en nueva barra o si el precio se movió >=5 ticks
    static datetime __sr_last_bar = 0;
    static double   __sr_last_probe = 0.0;
    datetime __sr_cur_bar = iTime(_Symbol, _Period, 0);
    double   __sr_point   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if(__sr_cur_bar == __sr_last_bar && MathAbs(currentPrice - __sr_last_probe) < 5.0*__sr_point){
        return touchContext.valid; // reutiliza el último estado
    }
    __sr_last_bar = __sr_cur_bar;
    __sr_last_probe = currentPrice;

    double minDistance = DBL_MAX;
    int bestIndex = -1;
    double bestQuality = 0;

    // DEBUG: Contador de niveles activos
    static int debugTouchCounter = 0;
    debugTouchCounter++;
    bool showDebug = (debugTouchCounter >= 100);
    if(showDebug) debugTouchCounter = 0;

    int activeLevels = 0;
    int initialLevels = 0;
    int confirmedLevels = 0;
    int levelsInRange = 0;

    // Buscar el mejor nivel tocado
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;

        activeLevels++;
        if(m_levels[i].state == SR_STATE_INITIAL) initialLevels++;
        if(m_levels[i].state >= SR_STATE_CONFIRMED) confirmedLevels++;

        // Solo permitir toques en niveles CONFIRMED o VALIDATED (el original)
        // Los niveles necesitan confirmarse primero para tener zonas adecuadas
        if(m_levels[i].state < SR_STATE_CONFIRMED) continue;

        double distance = MathAbs(currentPrice - m_levels[i].price);

        // Verificar si está dentro de la zona
        bool inZone = (currentPrice >= m_levels[i].zoneLow &&
                      currentPrice <= m_levels[i].zoneHigh);

        if(inZone) {
            levelsInRange++;
            // Calcular calidad del toque
            double quality = GetLevelImportance(m_levels[i]);

            // Priorizar por calidad, no solo por distancia
            if(quality > bestQuality ||
               (quality == bestQuality && distance < minDistance)) {
                minDistance = distance;
                bestIndex = i;
                bestQuality = quality;
            }
        }
    }

    // DEBUG: Mostrar estado cada 100 barras
    if(showDebug) {
        Print("╔═══ DEBUG: DetectSRTouch Estado ═══╗");
        Print("║ Precio actual: ", DoubleToString(currentPrice, _Digits));
        Print("║ Niveles activos: ", activeLevels);
        Print("║ Niveles INITIAL: ", initialLevels);
        Print("║ Niveles CONFIRMED+: ", confirmedLevels);
        Print("║ Niveles en rango: ", levelsInRange);
        if(bestIndex >= 0) {
            Print("║ Mejor nivel encontrado: ", m_levels[bestIndex].price);
            Print("║ Calidad: ", DoubleToString(bestQuality, 3));
        }
        Print("╚════════════════════════════════════╝");
    }

    // Si encontramos un nivel tocado
    if(bestIndex >= 0) {
        touchContext.valid = true;
        touchContext.price = currentPrice;
        touchContext.time = TimeCurrent();
        touchContext.level = m_levels[bestIndex];
        touchContext.quality = bestQuality;
        touchContext.reason = "Toque en zona SR de alta calidad";
        touchContext.detectedTimeframe = m_levels[bestIndex].sourceTimeframe;
        touchContext.distanceToLevel = minDistance;
        touchContext.levelStrength = m_levels[bestIndex].strength;
        touchContext.touchNumber = m_levels[bestIndex].touchCount + 1;

        // Verificar si es el primer toque reciente
        datetime timeSinceLastTouch = TimeCurrent() - m_levels[bestIndex].lastTouchTime;
        touchContext.isFirstTouch = (timeSinceLastTouch > PeriodSeconds(m_levels[bestIndex].sourceTimeframe) * 10);

        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| CALCULAR IMPORTANCIA DEL NIVEL                                  |
//+------------------------------------------------------------------+
double CSupportResistance::GetLevelImportance(const SRLevel &level) {
    int levelIndex = level.id;
    double importance = 0.0;
    
    // Factor 1: Estado (20%)
    switch(m_levels[levelIndex].state) {
        case SR_STATE_VALIDATED: importance += 0.2; break;
        case SR_STATE_CONFIRMED: importance += 0.1; break;
        case SR_STATE_INITIAL: importance += 0.05; break;
    }
    
    // Factor 2: Calidad (25%)
    switch(m_levels[levelIndex].quality) {
        case SR_QUALITY_EXTREME: importance += 0.25; break;
        case SR_QUALITY_CRITICAL: importance += 0.20; break;
        case SR_QUALITY_STRONG: importance += 0.15; break;
        case SR_QUALITY_NORMAL: importance += 0.10; break;
        case SR_QUALITY_WEAK: importance += 0.05; break;
    }
    
    // Factor 3: Número de toques (20%)
    double touchFactor = MathMin(0.2, m_levels[levelIndex].touchCount * 0.02);
    importance += touchFactor;
    
    // Factor 4: Fuerza (15%)
    double strengthFactor = MathMin(0.15, m_levels[levelIndex].strength * 0.03);
    importance += strengthFactor;
    
    // Factor 5: Timeframe (10%)
    switch(m_levels[levelIndex].sourceTimeframe) {
        case PERIOD_D1: importance += 0.10; break;
        case PERIOD_H4: importance += 0.08; break;
        case PERIOD_H1: importance += 0.06; break;
        case PERIOD_M30: importance += 0.04; break;
    }
    
    // Factor 6: Éxito de rebotes (10%)
    if(m_levels[levelIndex].touchCount > 0) {
        double successRate = (double)m_levels[levelIndex].successfulBounces / m_levels[levelIndex].touchCount;
        importance += successRate * 0.10;
    }
    
    return MathMin(1.0, importance);
}

//+------------------------------------------------------------------+
//| SISTEMA DE VOTACIÓN MEJORADO                                    |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CSupportResistance::GetVoteDirection(double &confidence) {
    confidence = 0.0;
    if(!m_initialized || m_levelCount == 0) return TREND_NONE;
    
    double currentPrice = m_currentBid;
    double bullScore = 0.0;
    double bearScore = 0.0;
    double totalWeight = 0.0;
    
    // Analizar todos los niveles activos
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active || m_levels[i].state < SR_STATE_CONFIRMED) continue;
        
        double dist = MathAbs(currentPrice - m_levels[i].price);
        double normalizedDist = dist / m_currentATR;
        
        // Factor distancia (más cerca = más influencia)
        double distanceFactor = 1.0 / (1.0 + normalizedDist * 0.3);
        
        // Importancia del nivel
        double importance = GetLevelImportance(m_levels[i]);
        
        // Peso combinado
        double weight = distanceFactor * importance;
        totalWeight += weight;
        
        // Asignar puntuación según tipo y posición
        if(m_levels[i].type == SR_SUPPORT) {
            if(currentPrice > m_levels[i].price) {
                // Precio sobre soporte = alcista
                bullScore += weight * 1.5;
            } else {
                // Precio bajo soporte = bajista débil
                bearScore += weight * 0.5;
            }
        }
        else { // RESISTANCE
            if(currentPrice < m_levels[i].price) {
                // Precio bajo resistencia = bajista
                bearScore += weight * 1.5;
            } else {
                // Precio sobre resistencia = alcista débil
                bullScore += weight * 0.5;
            }
        }
        
        // Bonus por niveles muy fuertes
        if(m_levels[i].quality >= SR_QUALITY_CRITICAL) {
            if(m_levels[i].type == SR_SUPPORT && currentPrice > m_levels[i].price) {
                bullScore += weight * 0.5;
            }
            else if(m_levels[i].type == SR_RESISTANCE && currentPrice < m_levels[i].price) {
                bearScore += weight * 0.5;
            }
        }
    }
    
    // Normalizar scores
    if(totalWeight > 0) {
        bullScore /= totalWeight;
        bearScore /= totalWeight;
    }
    
    // Determinar dirección y confianza
    if(bullScore > bearScore * 1.2) {
        confidence = (bullScore - bearScore) / (bullScore + bearScore);
        return TREND_UP;
    }
    else if(bearScore > bullScore * 1.2) {
        confidence = (bearScore - bullScore) / (bullScore + bearScore);
        return TREND_DOWN;
    }
    
    // Si hay un nivel extremadamente fuerte cerca
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active || m_levels[i].quality < SR_QUALITY_EXTREME) continue;
        
        double dist = MathAbs(currentPrice - m_levels[i].price);
        if(dist < m_currentATR * 0.5) {
            confidence = 0.8;
            if(m_levels[i].type == SR_SUPPORT) return TREND_UP;
            else return TREND_DOWN;
        }
    }
    
    confidence = 0.3;
    return TREND_NONE;
}

//+------------------------------------------------------------------+
//| ACTUALIZAR VISUALES DEL NIVEL                                   |
//+------------------------------------------------------------------+
void CSupportResistance::UpdateLevelVisuals(int levelIndex) {
    if(!m_showVisual || levelIndex < 0 || levelIndex >= MAX_SR_LEVELS) return;
    
    // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: level

    if(!m_levels[levelIndex].active) return;
    
    // Actualizar propiedades visuales
    m_levels[levelIndex].lineWidth = GetDynamicWidth(m_levels[levelIndex]);
    m_levels[levelIndex].lineColor = GetDynamicColor(m_levels[levelIndex]);
    
    // Actualizar etiqueta
    if(m_levels[levelIndex].state == SR_STATE_INITIAL) {
        m_levels[levelIndex].showLabel = true;
        m_levels[levelIndex].labelText = "1";
    }
    else if(m_levels[levelIndex].touchCount > 3) {
        m_levels[levelIndex].showLabel = true;
        m_levels[levelIndex].labelText = IntegerToString(m_levels[levelIndex].touchCount);
    }
    else {
        m_levels[levelIndex].showLabel = false;
    }
    
    // Actualizar objeto gráfico
    UpdateLevelObject(m_levels[levelIndex]);
    
    // Actualizar etiqueta si es necesario
    if(m_levels[levelIndex].showLabel) {
        UpdateLevelLabel(m_levels[levelIndex]);
    }
}

//+------------------------------------------------------------------+
//| OBTENER COLOR DINÁMICO                                          |
//+------------------------------------------------------------------+
color CSupportResistance::GetDynamicColor(const SRLevel &level) {
    int levelIndex = level.id;
    color baseColor = (m_levels[levelIndex].type == SR_SUPPORT) ? clrLime : clrRed;
    
    // Variar intensidad según calidad y estado
    switch(m_levels[levelIndex].quality) {
        case SR_QUALITY_EXTREME:
            return (m_levels[levelIndex].type == SR_SUPPORT) ? clrGold : clrMagenta;
            
        case SR_QUALITY_CRITICAL:
            return (m_levels[levelIndex].type == SR_SUPPORT) ? clrYellow : clrOrangeRed;
            
        case SR_QUALITY_STRONG:
            return (m_levels[levelIndex].type == SR_SUPPORT) ? clrLime : clrRed;
            
        case SR_QUALITY_NORMAL:
            return (m_levels[levelIndex].type == SR_SUPPORT) ? clrSpringGreen : clrIndianRed;
            
        case SR_QUALITY_WEAK:
            return (m_levels[levelIndex].type == SR_SUPPORT) ? clrPaleGreen : clrLightCoral;
    }
    
    return baseColor;
}

//+------------------------------------------------------------------+
//| OBTENER ANCHO DINÁMICO                                          |
//+------------------------------------------------------------------+
int CSupportResistance::GetDynamicWidth(const SRLevel &level) {
    int levelIndex = level.id;
    int width = 1;
    
    // Ancho según estado
    if(m_levels[levelIndex].state == SR_STATE_INITIAL) {
        width = 1;
    }
    else if(m_levels[levelIndex].state == SR_STATE_CONFIRMED) {
        width = 2;
    }
    else if(m_levels[levelIndex].state == SR_STATE_VALIDATED) {
        width = 3;
    }
    
    // Bonus por toques
    if(m_levels[levelIndex].touchCount >= 10) width = 5;
    else if(m_levels[levelIndex].touchCount >= 7) width = 4;
    else if(m_levels[levelIndex].touchCount >= 5) width = 3;
    
    // Máximo ancho
    return MathMin(5, width);
}

//+------------------------------------------------------------------+
//| FUNCIONES AUXILIARES                                            |
//+------------------------------------------------------------------+
void CSupportResistance::UpdateMarketContext() {
    // Actualizar ATR
    m_currentATR = GetATRForTimeframe(PERIOD_CURRENT);
    
    // Calcular volatilidad
    double atr_values[];
    int atr_handle = iATR(Symbol(), PERIOD_CURRENT, 14);
    if(atr_handle != INVALID_HANDLE) {
        if(CopyBuffer(atr_handle, 0, 0, 20, atr_values) == 20) {
            double avgATR = 0;
            for(int i = 0; i < 20; i++) avgATR += atr_values[i];
            avgATR /= 20.0;
            
            m_volatilityFactor = (avgATR > 0) ? m_currentATR / avgATR : 1.0;
        }
        IndicatorRelease(atr_handle);
    }
    
    // Calcular fuerza de tendencia
    MqlRates rates[];
    if(CopyRates(Symbol(), PERIOD_CURRENT, 0, 20, rates) == 20) {
        double highest = rates[0].high;
        double lowest = rates[0].low;
        
        for(int i = 1; i < 20; i++) {
            if(rates[i].high > highest) highest = rates[i].high;
            if(rates[i].low < lowest) lowest = rates[i].low;
        }
        
        double range = highest - lowest;
        double currentPos = (m_currentBid - lowest) / range;
        
        if(currentPos > 0.8) m_trendStrength = 1.0;
        else if(currentPos < 0.2) m_trendStrength = -1.0;
        else m_trendStrength = (currentPos - 0.5) * 2;
    }
}

int CSupportResistance::GetTimeframeIndex(ENUM_TIMEFRAMES tf) {
    for(int i = 0; i < 4; i++) {
        if(m_timeframes[i] == tf) return i;
    }
    return -1;
}

int CSupportResistance::FindNearestLevel(double price, ENUM_SR_TYPE type, ENUM_TIMEFRAMES tf) {
    double minDistance = DBL_MAX;
    int bestIndex = -1;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        if(m_levels[i].type != type) continue;
        if(m_levels[i].sourceTimeframe != tf) continue;
        
        double distance = MathAbs(price - m_levels[i].price);
        if(distance < minDistance) {
            minDistance = distance;
            bestIndex = i;
        }
    }
    
    return bestIndex;
}

bool CSupportResistance::IsNearExistingLevel(double price, ENUM_TIMEFRAMES tf, double tolerance) {
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(m_levels[i].active && 
           m_levels[i].sourceTimeframe == tf &&
           MathAbs(m_levels[i].price - price) <= tolerance) {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| CONSOLIDAR NIVELES CERCANOS                                     |
//+------------------------------------------------------------------+
void CSupportResistance::ConsolidateLevels() {
    int consolidated = 0;
    
    for(int i = 0; i < MAX_SR_LEVELS - 1; i++) {
        if(!m_levels[i].active) continue;
        
        for(int j = i + 1; j < MAX_SR_LEVELS; j++) {
            if(!m_levels[j].active) continue;
            
            // Si son del mismo tipo y timeframe
            if(m_levels[i].type == m_levels[j].type &&
               m_levels[i].sourceTimeframe == m_levels[j].sourceTimeframe) {
                
                double distance = MathAbs(m_levels[i].price - m_levels[j].price);
                double avgZone = (m_levels[i].currentZoneSize + m_levels[j].currentZoneSize) / 2;
                
                // Si están muy cerca
                if(distance <= avgZone * 0.5) {
                    // Mantener el más fuerte
                    int keepIdx = (GetLevelImportance(m_levels[i]) >= GetLevelImportance(m_levels[j])) ? i : j;
                    int removeIdx = (keepIdx == i) ? j : i;
                    
                    // Transferir información al que queda
                    m_levels[keepIdx].touchCount += m_levels[removeIdx].touchCount;
                    m_levels[keepIdx].successfulBounces += m_levels[removeIdx].successfulBounces;
                    m_levels[keepIdx].strength = MathMax(m_levels[keepIdx].strength, m_levels[removeIdx].strength);
                    
                    // Actualizar precio al promedio ponderado
                    double weight1 = m_levels[keepIdx].touchCount;
                    double weight2 = m_levels[removeIdx].touchCount;
                    m_levels[keepIdx].price = (m_levels[keepIdx].price * weight1 + 
                                              m_levels[removeIdx].price * weight2) / (weight1 + weight2);
                    
                    // Expandir zona
                    m_levels[keepIdx].currentZoneSize = MathMax(m_levels[keepIdx].currentZoneSize,
                                                               m_levels[removeIdx].currentZoneSize) * 1.1;
                    
                    // Actualizar zonas
                    m_levels[keepIdx].zoneHigh = m_levels[keepIdx].price + (m_levels[keepIdx].currentZoneSize / 2);
                    m_levels[keepIdx].zoneLow = m_levels[keepIdx].price - (m_levels[keepIdx].currentZoneSize / 2);
                    
                    // Actualizar estado si es necesario
                    if(m_levels[removeIdx].state > m_levels[keepIdx].state) {
                        m_levels[keepIdx].state = m_levels[removeIdx].state;
                    }
                    
                    // Invalidar el nivel eliminado
                    InvalidateLevel(removeIdx);
                    consolidated++;
                }
            }
        }
    }
    
    if(consolidated > 0) {
        Print("Niveles consolidados: ", consolidated);
    }
}

//+------------------------------------------------------------------+
//| VERIFICAR RUPTURAS CONSECUTIVAS                                 |
//+------------------------------------------------------------------+
void CSupportResistance::CheckInvalidations() {
    // Solo invalidamos niveles confirmados o posteriores y con respeto a una gracia de barras
    datetime now = TimeCurrent();
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        
        // Evitar parpadeo: no evaluar niveles recién creados
        int barsSinceCreation = Bars(Symbol(), m_levels[i].sourceTimeframe, m_levels[i].creationTime, now);
        if(m_levels[i].state < SR_STATE_CONFIRMED) {
            // Deje que CheckLevelConfirmation gestione los no confirmados
            if(barsSinceCreation < INVALIDATION_GRACE_BARS) {
                m_levels[i].consecutiveBreaks = 0;
                continue;
            }
        } else {
            // Opcional: pequeña gracia tras confirmación para estabilizar
            int barsSinceConfirm = (m_levels[i].confirmationTime > 0)
                                    ? Bars(Symbol(), m_levels[i].sourceTimeframe, m_levels[i].confirmationTime, now)
                                    : barsSinceCreation;
            if(barsSinceConfirm < 1) {
                m_levels[i].consecutiveBreaks = 0;
                continue;
            }
        }
        
        if(CheckConsecutiveBreaks(m_levels[i])) {
            if(m_levels[i].consecutiveBreaks >= INVALIDATION_CANDLES) {
                Print("Nivel invalidado por ", INVALIDATION_CANDLES, " rupturas consecutivas: ",
                      EnumToString(m_levels[i].sourceTimeframe), " ",
                      DoubleToString(m_levels[i].price, _Digits));
                
                m_levels[i].state = SR_STATE_BROKEN;
                m_levels[i].locked = true; 
                m_levels[i].lock_time = now;
                InvalidateLevel(i);
            }
        } else {
            // Reset contador si no hay ruptura
            m_levels[i].consecutiveBreaks = 0;
        }
    }
}

bool CSupportResistance::CheckConsecutiveBreaks(SRLevel &level) {
    // Evaluar rupturas consecutivas SOLO desde la creación/confirmación hacia adelante
    const int levelIndex = level.id;
    if(levelIndex < 0 || levelIndex >= MAX_SR_LEVELS) return false;
    
    // No invalidar niveles que nunca han sido tocados/confirmados
    if(level.state < SR_STATE_CONFIRMED && level.touchCount == 0) {
        level.consecutiveBreaks = 0;
        return false;
    }
    
    datetime startTime = (level.confirmationTime > 0) ? level.confirmationTime : level.creationTime;
    datetime now = TimeCurrent();
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(Symbol(), level.sourceTimeframe, startTime, now, rates);
    if(copied <= 0) { 
        level.consecutiveBreaks = 0; 
        return false; 
    }
    
    // Revisar SOLO las últimas N velas posteriores al startTime
    int toCheck = MathMin(INVALIDATION_CANDLES, copied);
    int consecutiveBreaks = 0;
    
    // Umbral dinámico: 10% del tamaño de la zona
    const double band = level.currentZoneSize * 0.10;
    
    for(int i = 0; i < toCheck; i++) {
        bool broken = false;
        double close = rates[i].close;
        
        if(level.type == SR_SUPPORT) {
            // Para soporte: close por debajo del límite inferior - banda
            if(close < (level.zoneLow - band)) broken = true;
        } else { // RESISTENCIA
            // Para resistencia: close por encima del límite superior + banda
            if(close > (level.zoneHigh + band)) broken = true;
        }
        
        if(broken) {
            consecutiveBreaks++;
        } else {
            break; // Serie interrumpida
        }
    }
    
    level.consecutiveBreaks = consecutiveBreaks;
    
    // Opcional: si hubo intentos pero no llegó a INVALIDATION_CANDLES, contar como ruptura fallida
    if(consecutiveBreaks > 0 && consecutiveBreaks < INVALIDATION_CANDLES) {
        level.failedBreaks++;
    }
    
    return (consecutiveBreaks > 0);
}

//+------------------------------------------------------------------+
//| MÉTODOS DE LIMPIEZA                                            |
//+------------------------------------------------------------------+
void CSupportResistance::CleanupOldLevels() {
    datetime currentTime = TimeCurrent();
    int removed = 0;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        
        // Remover niveles sin toques recientes
        datetime timeSinceTouch = currentTime - m_levels[i].lastTouchTime;
        datetime ageThreshold = 48 * 3600; // 48 horas base
        
        // Niveles más fuertes pueden permanecer más tiempo
        if(m_levels[i].quality >= SR_QUALITY_STRONG) {
            ageThreshold = 72 * 3600; // 72 horas
        }
        if(m_levels[i].quality >= SR_QUALITY_CRITICAL) {
            ageThreshold = 96 * 3600; // 96 horas
        }
        
        if(timeSinceTouch > ageThreshold) {
            InvalidateLevel(i);
            removed++;
        }
    }
    
    if(removed > 0) {
        Print("Limpieza: ", removed, " niveles antiguos removidos");
    }
}

void CSupportResistance::RemoveWeakLevels() {
    int removed = 0;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        
        // Criterios para nivel débil
        bool isWeak = false;
        
        // Niveles iniciales sin confirmación después de tiempo
        if(m_levels[i].state == SR_STATE_INITIAL) {
            datetime age = TimeCurrent() - m_levels[i].creationTime;
            if(age > PeriodSeconds(m_levels[i].sourceTimeframe) * m_confirmationBars) {
                isWeak = true;
            }
        }
        // Niveles confirmados pero con muy pocos toques
        else if(m_levels[i].state == SR_STATE_CONFIRMED) {
            if(m_levels[i].touchCount < 2 && m_levels[i].strength < 2.0) {
                datetime age = TimeCurrent() - m_levels[i].confirmationTime;
                if(age > 3600) { // Más de 1 hora
                    isWeak = true;
                }
            }
        }
        
        // Alta tasa de fallos
        if(m_levels[i].touchCount > 0) {
            double failRate = (double)m_levels[i].failedBreaks / m_levels[i].touchCount;
            if(failRate > 0.5) {
                isWeak = true;
            }
        }
        
        if(isWeak) {
            InvalidateLevel(i);
            removed++;
        }
    }
    
    if(removed > 0) {
        Print("Limpieza: ", removed, " niveles débiles removidos");
    }
}

//+------------------------------------------------------------------+
//| MÉTODOS DE CONSULTA MEJORADOS                                   |
//+------------------------------------------------------------------+
int CSupportResistance::GetStrongLevels(SRLevel &levels[], double minStrength) {
    ArrayResize(levels, 0);
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        if(m_levels[i].strength < minStrength) continue;
        if(m_levels[i].state < SR_STATE_CONFIRMED) continue;
        
        int size = ArraySize(levels);
        ArrayResize(levels, size + 1);
        levels[size] = m_levels[i];
    }
    
    // Ordenar por fuerza descendente
    for(int i = 0; i < ArraySize(levels) - 1; i++) {
        for(int j = i + 1; j < ArraySize(levels); j++) {
            if(levels[j].strength > levels[i].strength) {
                SRLevel temp = levels[i];
                levels[i] = levels[j];
                levels[j] = temp;
            }
        }
    }
    
    return ArraySize(levels);
}

int CSupportResistance::GetConfirmedLevels(SRLevel &levels[], ENUM_SR_STATE minState) {
    ArrayResize(levels, 0);
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        if(m_levels[i].state < minState) continue;
        
        int size = ArraySize(levels);
        ArrayResize(levels, size + 1);
        levels[size] = m_levels[i];
    }
    
    return ArraySize(levels);
}

double CSupportResistance::GetNearestSupportPrice(double currentPrice) {
    double nearestPrice = 0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active || m_levels[i].type != SR_SUPPORT) continue;
        if(m_levels[i].state < SR_STATE_CONFIRMED) continue;
        if(m_levels[i].price >= currentPrice) continue; // Solo soportes por debajo
        
        double distance = currentPrice - m_levels[i].price;
        if(distance < minDistance) {
            minDistance = distance;
            nearestPrice = m_levels[i].price;
        }
    }
    
    return nearestPrice;
}

double CSupportResistance::GetNearestResistancePrice(double currentPrice) {
    double nearestPrice = 0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active || m_levels[i].type != SR_RESISTANCE) continue;
        if(m_levels[i].state < SR_STATE_CONFIRMED) continue;
        if(m_levels[i].price <= currentPrice) continue; // Solo resistencias por encima
        
        double distance = m_levels[i].price - currentPrice;
        if(distance < minDistance) {
            minDistance = distance;
            nearestPrice = m_levels[i].price;
        }
    }
    
    return nearestPrice;
}

//+------------------------------------------------------------------+
//| FUNCIONES DE VISUALIZACIÓN                                      |
//+------------------------------------------------------------------+
void CSupportResistance::CreateLevelObject(SRLevel &level) {
    int levelIndex = level.id;
    if(!m_showVisual || m_levels[levelIndex].objectName != "") return;
    
    string objName = GenerateObjectName(m_levels[levelIndex].id, m_levels[levelIndex].sourceTimeframe);
    
    if(ObjectCreate(0, objName, OBJ_HLINE, 0, 0, m_levels[levelIndex].price)) {
        ObjectSetInteger(0, objName, OBJPROP_COLOR, m_levels[levelIndex].lineColor);
        ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, objName, OBJPROP_WIDTH, m_levels[levelIndex].lineWidth);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_BACK, true);
        
        string tooltip = StringFormat("%s %s %.5f | Estado:%s | Toques:%d | Fuerza:%.1f",
                                     (m_levels[levelIndex].type == SR_SUPPORT ? "SOPORTE" : "RESISTENCIA"),
                                     EnumToString(m_levels[levelIndex].sourceTimeframe),
                                     m_levels[levelIndex].price,
                                     GetStateString(m_levels[levelIndex].state),
                                     m_levels[levelIndex].touchCount,
                                     m_levels[levelIndex].strength);
        
        ObjectSetString(0, objName, OBJPROP_TOOLTIP, tooltip);
        
        m_levels[levelIndex].objectName = objName;
        m_levels[levelIndex].isVisible = true;
        
        // Crear etiqueta si es necesario
        if(m_levels[levelIndex].showLabel) {
            CreateLevelLabel(level);
        }
    }
}

void CSupportResistance::UpdateLevelObject(SRLevel &level) {
    int levelIndex = level.id;
// Bloqueo de nivel: desbloquear tras 48 h
if(level.locked)
{
    if(TimeCurrent() - level.lock_time >= SR_LOCK_DURATION)
    {
        level.locked = false;
        level.state  = SR_STATE_INITIAL;
    }
    else
    {
        // Aún bloqueado -> omitir procesamiento
        return;
    }
}
    if(!m_showVisual || m_levels[levelIndex].objectName == "") return;
    
    if(ObjectFind(0, m_levels[levelIndex].objectName) >= 0) {
        // Actualizar propiedades visuales
        ObjectSetInteger(0, m_levels[levelIndex].objectName, OBJPROP_COLOR, m_levels[levelIndex].lineColor);
        ObjectSetInteger(0, m_levels[levelIndex].objectName, OBJPROP_WIDTH, m_levels[levelIndex].lineWidth);
        
        // Actualizar tooltip
        string tooltip = StringFormat("%s %s %.5f | Estado:%s | Toques:%d | Fuerza:%.1f | Calidad:%s",
                                     (m_levels[levelIndex].type == SR_SUPPORT ? "SOPORTE" : "RESISTENCIA"),
                                     EnumToString(m_levels[levelIndex].sourceTimeframe),
                                     m_levels[levelIndex].price,
                                     GetStateString(m_levels[levelIndex].state),
                                     m_levels[levelIndex].touchCount,
                                     m_levels[levelIndex].strength,
                                     GetQualityString(m_levels[levelIndex].quality));
        
        ObjectSetString(0, m_levels[levelIndex].objectName, OBJPROP_TOOLTIP, tooltip);
        
        // Actualizar posición si cambió
        ObjectSetDouble(0, m_levels[levelIndex].objectName, OBJPROP_PRICE, m_levels[levelIndex].price);
    }
}

void CSupportResistance::CreateLevelLabel(SRLevel &level) {
    int levelIndex = level.id;
    if(!m_showVisual || !m_levels[levelIndex].showLabel) return;
    
    string labelName = m_levels[levelIndex].objectName + "_label";
    
    if(ObjectFind(0, labelName) < 0) {
        if(ObjectCreate(0, labelName, OBJ_TEXT, 0, TimeCurrent(), m_levels[levelIndex].price)) {
            ObjectSetString(0, labelName, OBJPROP_TEXT, m_levels[levelIndex].labelText);
            ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, m_levels[levelIndex].lineColor);
            ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
        }
    }
}

void CSupportResistance::UpdateLevelLabel(SRLevel &level) {
    int levelIndex = level.id;
    if(!m_showVisual) return;
    
    string labelName = m_levels[levelIndex].objectName + "_label";
    
    if(m_levels[levelIndex].showLabel) {
        if(ObjectFind(0, labelName) >= 0) {
            ObjectSetString(0, labelName, OBJPROP_TEXT, m_levels[levelIndex].labelText);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, m_levels[levelIndex].lineColor);
            ObjectMove(0, labelName, 0, TimeCurrent(), m_levels[levelIndex].price);
        } else {
            CreateLevelLabel(level);
        }
    } else {
        // Eliminar etiqueta si no debe mostrarse
        if(ObjectFind(0, labelName) >= 0) {
            ObjectDelete(0, labelName);
        }
    }
}

void CSupportResistance::RemoveLevelObject(SRLevel &level) {
    int levelIndex = level.id;
    if(m_levels[levelIndex].objectName == "") return;
    
    if(ObjectFind(0, m_levels[levelIndex].objectName) >= 0) {
        ObjectDelete(0, m_levels[levelIndex].objectName);
    }
    
    // Eliminar etiqueta también
    string labelName = m_levels[levelIndex].objectName + "_label";
    if(ObjectFind(0, labelName) >= 0) {
        ObjectDelete(0, labelName);
    }
    
    m_levels[levelIndex].objectName = "";
    m_levels[levelIndex].isVisible = false;
}

//+------------------------------------------------------------------+
//| FUNCIONES DE UTILIDAD                                           |
//+------------------------------------------------------------------+
void CSupportResistance::InitializeArrays() {
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        m_levels[i].id = i;
        m_levels[i].active = false;
        m_levels[i].isVisible = false;
        m_levels[i].objectName = "";
        m_levels[i].price = 0.0;
        m_levels[i].strength = 0.0;
        m_levels[i].touchCount = 0;
        m_levels[i].quality = SR_QUALITY_WEAK;
        m_levels[i].state = SR_STATE_INITIAL;
        m_levels[i].consecutiveBreaks = 0;
        
        // Inicializar arrays internos
        for(int j = 0; j < 20; j++) {
            m_levels[i].touchTimes[j] = 0;
            m_levels[i].touchPrices[j] = 0;
            m_levels[i].touchStrengths[j] = 0;
        }
    }
    m_levelCount = 0;
}

void CSupportResistance::CleanupGraphics() {
    if(!m_showVisual) return;
    
    ObjectsDeleteAll(0, m_prefix);
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        m_levels[i].isVisible = false;
        m_levels[i].objectName = "";
    }
}

void CSupportResistance::ForceVisualUpdate() {
    if(!m_showVisual) return;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(m_levels[i].active) {
            UpdateLevelVisuals(i);
        }
    }
}

string CSupportResistance::GenerateObjectName(int id, ENUM_TIMEFRAMES tf) {
    return m_prefix + EnumToString(tf) + "_L" + IntegerToString(id) + "_" + 
           IntegerToString(TimeCurrent() % 100000);
}

double CSupportResistance::GetATRForTimeframe(ENUM_TIMEFRAMES tf, int period) {
    double atr = 0.0;
    int atrHandle = iATR(Symbol(), tf, period);
    
    if(atrHandle != INVALID_HANDLE) {
        double atrBuf[];
        ArraySetAsSeries(atrBuf, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 1, atrBuf) > 0) {
            atr = atrBuf[0];
        }
        
        IndicatorRelease(atrHandle);
    }
    
    if(atr <= 0.0) {
        atr = 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    }
    
    return atr;
}

double CSupportResistance::CalculateZoneSize(ENUM_TIMEFRAMES tf, double barSize) {
    // La zona inicial es del tamaño de la última vela
    double baseSize = barSize;
    
    // Ajustar ligeramente por timeframe
    switch(tf) {
        case PERIOD_D1: baseSize *= 1.2; break;
        case PERIOD_H4: baseSize *= 1.1; break;
        case PERIOD_H1: baseSize *= 1.0; break;
        case PERIOD_M30: baseSize *= 0.9; break;
    }
    
    return baseSize;
}

//+------------------------------------------------------------------+
//| FUNCIONES DE DEBUG Y ESTADÍSTICAS                               |
//+------------------------------------------------------------------+
void CSupportResistance::PrintStatistics() {
    Print("=== ESTADÍSTICAS S/R v4.0 ===");
    Print("Niveles activos: ", m_levelCount, " / ", MAX_SR_LEVELS);
    
    int countByState[4] = {0, 0, 0, 0};
    int countByQuality[5] = {0, 0, 0, 0, 0};
    int supportCount = 0, resistanceCount = 0;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(m_levels[i].active) {
            countByState[m_levels[i].state]++;
            countByQuality[m_levels[i].quality]++;
            
            if(m_levels[i].type == SR_SUPPORT) supportCount++;
            else resistanceCount++;
        }
    }
    
    Print("Por Estado:");
    Print("  Inicial: ", countByState[SR_STATE_INITIAL]);
    Print("  Confirmado: ", countByState[SR_STATE_CONFIRMED]);
    Print("  Validado: ", countByState[SR_STATE_VALIDATED]);
    
    Print("Por Calidad:");
    Print("  Extrema: ", countByQuality[SR_QUALITY_EXTREME]);
    Print("  Crítica: ", countByQuality[SR_QUALITY_CRITICAL]);
    Print("  Fuerte: ", countByQuality[SR_QUALITY_STRONG]);
    Print("  Normal: ", countByQuality[SR_QUALITY_NORMAL]);
    Print("  Débil: ", countByQuality[SR_QUALITY_WEAK]);
    
    Print("Soportes: ", supportCount, " | Resistencias: ", resistanceCount);
    Print("====================================");
}

void CSupportResistance::PrintNearbyLevels(double price, double range) {
    Print("=== NIVELES CERCANOS A ", DoubleToString(price, _Digits), " ===");
    
    SRLevel nearbyLevels[];
    int count = GetLevelsInRange(price - range, price + range, nearbyLevels);
    
    for(int i = 0; i < count; i++) {
        Print(StringFormat("%s @ %.5f | TF:%s | Estado:%s | Toques:%d | Fuerza:%.1f | Importancia:%.2f",
                          (nearbyLevels[i].type == SR_SUPPORT ? "SOP" : "RES"),
                          nearbyLevels[i].price,
                          EnumToString(nearbyLevels[i].sourceTimeframe),
                          GetStateString(nearbyLevels[i].state),
                          nearbyLevels[i].touchCount,
                          nearbyLevels[i].strength,
                          GetLevelImportance(nearbyLevels[i])));
    }
    
    if(count == 0) {
        Print("No hay niveles en el rango especificado");
    }
}

void CSupportResistance::PrintMovementAnalysis() {
    Print("=== ANÁLISIS DE MOVIMIENTOS ACTUALES ===");
    
    for(int i = 0; i < 4; i++) {
        if(!m_tfEnabled[i]) continue;
        
        Print(EnumToString(m_timeframes[i]), ":");
        
        if(m_trackingMovement[i]) {
            // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: mov

            Print("  Rastreando movimiento ", GetMovementTypeString(m_currentMovements[i].type));
            Print("  Desde: ", DoubleToString(m_currentMovements[i].startPrice, _Digits),
                  " Hasta: ", DoubleToString(m_currentMovements[i].endPrice, _Digits));
            Print("  Tamaño: ", DoubleToString(m_currentMovements[i].totalSize/_Point, 0), " pts");
            Print("  Barras: ", m_currentMovements[i].barCount);
            Print("  Fuerza: ", DoubleToString(m_currentMovements[i].strength, 2));
        } else {
            Print("  Sin movimiento activo");
        }
    }
    
    Print("=====================================");
}

void CSupportResistance::PrintLevelDetails(int levelId) {
    if(levelId < 0 || levelId >= MAX_SR_LEVELS || !m_levels[levelId].active) {
        Print("Nivel inválido o inactivo");
        return;
    }
    
    // Eliminado alias
    // // Eliminado alias
    // // Alias eliminado: level

    
    Print("=== DETALLES DEL NIVEL ", levelId, " ===");
    Print("Tipo: ", (m_levels[levelId].type == SR_SUPPORT ? "SOPORTE" : "RESISTENCIA"));
    Print("Precio: ", DoubleToString(m_levels[levelId].price, _Digits));
    Print("Zona: ", DoubleToString(m_levels[levelId].zoneLow, _Digits), " - ", 
          DoubleToString(m_levels[levelId].zoneHigh, _Digits));
    Print("Estado: ", GetStateString(m_levels[levelId].state));
    Print("Calidad: ", GetQualityString(m_levels[levelId].quality));
    Print("Timeframe: ", EnumToString(m_levels[levelId].sourceTimeframe));
    Print("Toques: ", m_levels[levelId].touchCount);
    Print("Fuerza: ", DoubleToString(m_levels[levelId].strength, 2));
    Print("Importancia: ", DoubleToString(GetLevelImportance(m_levels[levelId]), 3));
    Print("Rebotes exitosos: ", m_levels[levelId].successfulBounces);
    Print("Rupturas fallidas: ", m_levels[levelId].failedBreaks);
    
    Print("Movimiento original:");
    Print("  Tipo: ", GetMovementTypeString(m_levels[levelId].originalMovement.type));
    Print("  Tamaño: ", DoubleToString(m_levels[levelId].originalMovement.totalSize/_Point, 0), " pts");
    Print("  Barras: ", m_levels[levelId].originalMovement.barCount);
    Print("  Fuerza: ", DoubleToString(m_levels[levelId].originalMovement.strength, 2));
    
    Print("Últimos toques:");
    for(int i = 0; i < 5 && m_levels[levelId].touchTimes[i] > 0; i++) {
        Print("  ", TimeToString(m_levels[levelId].touchTimes[i]), " @ ", 
              DoubleToString(m_levels[levelId].touchPrices[i], _Digits));
    }
    
    Print("===================================");
}

//+------------------------------------------------------------------+
//| FUNCIONES AUXILIARES DE STRING                                  |
//+------------------------------------------------------------------+
string CSupportResistance::GetStateString(ENUM_SR_STATE state) {
    switch(state) {
        case SR_STATE_INITIAL: return "Inicial";
        case SR_STATE_CONFIRMED: return "Confirmado";
        case SR_STATE_VALIDATED: return "Validado";
        case SR_STATE_BROKEN: return "Roto";
        default: return "Desconocido";
    }
}

string CSupportResistance::GetQualityString(ENUM_SR_QUALITY quality) {
    switch(quality) {
        case SR_QUALITY_EXTREME: return "EXTREMA";
        case SR_QUALITY_CRITICAL: return "Crítica";
        case SR_QUALITY_STRONG: return "Fuerte";
        case SR_QUALITY_NORMAL: return "Normal";
        case SR_QUALITY_WEAK: return "Débil";
        default: return "?";
    }
}

string CSupportResistance::GetMovementTypeString(ENUM_MOVEMENT_TYPE type) {
    switch(type) {
        case MOVEMENT_BULLISH: return "Alcista";
        case MOVEMENT_BEARISH: return "Bajista";
        case MOVEMENT_IMPULSE: return "Impulso";
        case MOVEMENT_CORRECTIVE: return "Correctivo";
        case MOVEMENT_NONE: return "Ninguno";
        default: return "?";
    }
}

//+------------------------------------------------------------------+
//| MÉTODOS DE ACCESO PÚBLICO                                       |
//+------------------------------------------------------------------+
bool CSupportResistance::GetLevelByIndex(int index, SRLevel &level) {
    int levelIndex = level.id;
    if(index < 0 || index >= MAX_SR_LEVELS) return false;
    if(!m_levels[index].active) return false;
    
    level = m_levels[index];
    return true;
}

int CSupportResistance::GetLevelsInRange(double priceFrom, double priceTo, SRLevel &levels[]) {
    ArrayResize(levels, 0);
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        
        if(m_levels[i].price >= priceFrom && m_levels[i].price <= priceTo) {
            int size = ArraySize(levels);
            ArrayResize(levels, size + 1);
            levels[size] = m_levels[i];
        }
    }
    
    return ArraySize(levels);
}

bool CSupportResistance::GetNearestLevel(double price, SRLevel &level, ENUM_SR_TYPE preferredType) {
    double minDistance = DBL_MAX;
    int bestIndex = -1;
    
    // Primero buscar del tipo preferido
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(!m_levels[i].active) continue;
        if(m_levels[i].state < SR_STATE_CONFIRMED) continue;
        
        if(preferredType != SR_SUPPORT && m_levels[i].type != preferredType) {
            continue;
        }
        
        double distance = MathAbs(price - m_levels[i].price);
        
        if(distance < minDistance) {
            minDistance = distance;
            bestIndex = i;
        }
    }
    
    // Si no encontramos del tipo preferido, buscar cualquiera
    if(bestIndex == -1) {
        for(int i = 0; i < MAX_SR_LEVELS; i++) {
            if(!m_levels[i].active) continue;
            if(m_levels[i].state < SR_STATE_CONFIRMED) continue;
            
            double distance = MathAbs(price - m_levels[i].price);
            
            if(distance < minDistance) {
                minDistance = distance;
                bestIndex = i;
            }
        }
    }
    
    if(bestIndex >= 0) {
        level = m_levels[bestIndex];
        return true;
    }
    
    int levelIndex = level.id;
    return false;
}

bool CSupportResistance::GetLevelDetails(int levelId, SRLevel &level) {
    int levelIndex = level.id;
    if(levelId < 0 || levelId >= MAX_SR_LEVELS) return false;
    if(!m_levels[levelId].active) return false;
    
    level = m_levels[levelId];
    return true;
}

//+------------------------------------------------------------------+
//| CONFIGURACIÓN DE PARÁMETROS                                     |
//+------------------------------------------------------------------+
bool CSupportResistance::ConfigureTimeframes(bool useM30, bool useH1, bool useH4, bool useD1) {
    m_tfEnabled[0] = useM30;
    m_tfEnabled[1] = useH1;
    m_tfEnabled[2] = useH4;
    m_tfEnabled[3] = useD1;
    
    // Verificar que al menos uno esté activo
    bool anyActive = false;
    for(int i = 0; i < 4; i++) {
        if(m_tfEnabled[i]) {
            anyActive = true;
            break;
        }
    }
    
    if(!anyActive) {
        Print("Error: Debe haber al menos un timeframe activo");
        m_tfEnabled[1] = true; // Activar H1 por defecto
    }
    
    return true;
}

void CSupportResistance::SetParameters(double minMovementATR, int confirmBars) {
    m_minMovementSize = MathMax(1.0, minMovementATR);
    m_confirmationBars = MathMax(10, confirmBars);
    
    Print("SR v4 Parámetros: MinMovimiento=", m_minMovementSize, " ATRs",
          " VelasConfirmación=", m_confirmationBars);
}

//+------------------------------------------------------------------+
//| VISUALIZACIÓN FILTRADA                                          |
//+------------------------------------------------------------------+
void CSupportResistance::ShowTimeframeFilter(ENUM_TIMEFRAMES tf) {
    if(!m_showVisual) return;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(m_levels[i].active && m_levels[i].objectName != "") {
            if(m_levels[i].sourceTimeframe == tf) {
                ObjectSetInteger(0, m_levels[i].objectName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            } else {
                ObjectSetInteger(0, m_levels[i].objectName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
        }
    }
}

void CSupportResistance::HideTimeframeFilter(ENUM_TIMEFRAMES tf) {
    ShowTimeframeFilter(PERIOD_CURRENT); // Mostrar todos
}

void CSupportResistance::ShowStrongLevelsOnly(double minStrength) {
    if(!m_showVisual) return;
    
    for(int i = 0; i < MAX_SR_LEVELS; i++) {
        if(m_levels[i].active && m_levels[i].objectName != "") {
            if(m_levels[i].strength >= minStrength) {
                ObjectSetInteger(0, m_levels[i].objectName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            } else {
                ObjectSetInteger(0, m_levels[i].objectName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Invalidar un nivel                                              |
//+------------------------------------------------------------------+
void CSupportResistance::InvalidateLevel(int levelIndex) {
    if(levelIndex < 0 || levelIndex >= MAX_SR_LEVELS) return;
    
    // Eliminar objeto visual
    if(m_showVisual) {
        RemoveLevelObject(m_levels[levelIndex]);
    }
       
    
    // Desactivar nivel
    m_levels[levelIndex].active = false;
    m_levelCount--;
}

#endif // SUPPORTRESISTANCE_V4_MQH