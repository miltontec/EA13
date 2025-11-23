#ifndef __BREAKOUTDETECTOR_FIXED_MQH__
#define __BREAKOUTDETECTOR_FIXED_MQH__

// Forward declaration to avoid circular dependency
struct SRLevel;
//+------------------------------------------------------------------+
//|                                           BreakoutDetector.mqh   |
//|                        Copyright 2025, Trading Strategy Developer |
//|                        DETECTOR DE BREAKOUTS INSTITUCIONALES      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Strategy Developer"
#property link      "https://www.domain.com"

#include <SupportResistance.mqh>
#include <PatternMemory.mqh>


//+------------------------------------------------------------------+
//| ENUMERACIONES Y ESTRUCTURAS                                      |
//+------------------------------------------------------------------+

enum ENUM_BREAKOUT_TYPE {
   BREAKOUT_NONE,
   BREAKOUT_SUPPORT,      // Ruptura de soporte (bajista)
   BREAKOUT_RESISTANCE,   // Ruptura de resistencia (alcista)
   BREAKOUT_FALSE         // Ruptura falsa
};

enum ENUM_BREAKOUT_STRENGTH {
   BREAKOUT_WEAK,
   BREAKOUT_MODERATE,
   BREAKOUT_STRONG,
   BREAKOUT_EXPLOSIVE
};

struct BreakoutSignal {
   datetime        time;
   double          breakoutPrice;
   ENUM_BREAKOUT_TYPE type;
   ENUM_BREAKOUT_STRENGTH strength;
   double          volume;
   double          momentum;
   bool            confirmed;
   int             confirmationBars;
   double          pullbackDepth;
   bool            hadPullback;
   int             srLevelId;
   double          targetPrice;
   double          stopPrice;
};

struct BreakoutStats {
   int             totalBreakouts;
   int             successfulBreakouts;
   int             falseBreakouts;
   double          avgMomentum;
   double          avgVolume;
   double          successRate;
};

//+------------------------------------------------------------------+
//| CLASE PRINCIPAL - DETECTOR DE BREAKOUTS                         |
//+------------------------------------------------------------------+

class CBreakoutDetector {
private:
   // Configuración
   ENUM_TIMEFRAMES m_timeframe;
   bool            m_showVisual;
   bool            m_initialized;
   string          m_prefix;
   
   // Parámetros de detección
   double          m_minBreakoutPercent;    // % mínimo para considerar breakout
   int             m_confirmationBars;      // Barras para confirmar
   double          m_volumeThreshold;       // Multiplicador de volumen
   double          m_pullbackMaxPercent;    // % máximo de pullback
   
   // Estado actual
   BreakoutSignal  m_currentBreakout;
   BreakoutSignal  m_recentBreakouts[10];
   int             m_breakoutCount;
   BreakoutStats   m_stats;
   
   // Variables de análisis
   ENUM_TREND_DIRECTION m_lastDirection;
   double          m_lastConfidence;
   bool            m_divergenceDetected;
   
   // Handles de indicadores
   int             m_atrHandle;
   int             m_volumeHandle;
   int             m_momentumHandle;
   int             m_rsiHandle;
   
   // Métodos privados
   bool            DetectBreakout(const MqlRates &rates[], int count, SRLevel &levels[], int levelCount);
   ENUM_BREAKOUT_STRENGTH CalculateBreakoutStrength(double priceMove, double volume, double atr);
   bool            ValidateBreakout(const BreakoutSignal &signal, const MqlRates &rates[], int currentBar);
   double          CalculateMomentum(const MqlRates &rates[], int startBar, int period);
   bool            CheckVolumeSpike(const MqlRates &rates[], int bar, double threshold);
   bool            IsFalseBreakout(const BreakoutSignal &signal, const MqlRates &rates[], int currentBar);
   void            UpdateBreakoutStats();
   double          GetAverageVolume(const MqlRates &rates[], int period);
   bool            HasRetestOccurred(const BreakoutSignal &signal, const MqlRates &rates[], int currentBar);
   void            Cleanup();  // Función auxiliar para limpiar handles
   // Métodos de visualización
   void            DrawBreakoutZone(const BreakoutSignal &signal);
   void            DrawBreakoutArrow(const BreakoutSignal &signal);
   color           GetBreakoutColor(ENUM_BREAKOUT_TYPE type, ENUM_BREAKOUT_STRENGTH strength);
   
public:
   CBreakoutDetector();
   ~CBreakoutDetector();
   
   // Métodos principales
   bool            Init(ENUM_TIMEFRAMES timeframe, bool showVisual = true);
   
   // MÉTODOS CLAVE PARA SISTEMA DE VOTACIÓN
   ENUM_TREND_DIRECTION GetImmediateDirection();
   double          GetDirectionConfidence();
   
   // Métodos de análisis
   bool            AnalyzeBreakouts(SRLevel &levels[], int levelCount);
   bool            HasActiveBreakout() { return m_currentBreakout.confirmed; }
   BreakoutSignal  GetCurrentBreakout() { return m_currentBreakout; }
   
   // Métodos de configuración
   void            SetMinBreakoutPercent(double percent) { m_minBreakoutPercent = percent; }
   void            SetConfirmationBars(int bars) { m_confirmationBars = bars; }
   void            SetVolumeThreshold(double threshold) { m_volumeThreshold = threshold; }
   
   // Métodos de información
   BreakoutStats   GetStatistics() { return m_stats; }
   void            PrintBreakoutAnalysis();
   void            UpdateVisual();
};

//+------------------------------------------------------------------+
//| Función auxiliar para limpiar handles                           |
//+------------------------------------------------------------------+
void CBreakoutDetector::Cleanup() {
   if(m_atrHandle != INVALID_HANDLE) {
      IndicatorRelease(m_atrHandle);
      m_atrHandle = INVALID_HANDLE;
   }
   
   if(m_volumeHandle != INVALID_HANDLE) {
      IndicatorRelease(m_volumeHandle);
      m_volumeHandle = INVALID_HANDLE;
   }
   
   if(m_momentumHandle != INVALID_HANDLE) {
      IndicatorRelease(m_momentumHandle);
      m_momentumHandle = INVALID_HANDLE;
   }
   
   if(m_rsiHandle != INVALID_HANDLE) {
      IndicatorRelease(m_rsiHandle);
      m_rsiHandle = INVALID_HANDLE;
   }
   
   // Limpiar objetos visuales si están activos
   if(m_showVisual) {
      ObjectsDeleteAll(0, m_prefix);
   }
}

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBreakoutDetector::CBreakoutDetector() {
   m_timeframe = PERIOD_CURRENT;
   m_showVisual = true;
   m_initialized = false;
   m_prefix = "BREAKOUT_";
   
   // Parámetros por defecto
   m_minBreakoutPercent = 0.15;   // 0.15% mínimo
   m_confirmationBars = 2;        // 2 barras de confirmación
   m_volumeThreshold = 1.5;       // 50% más volumen
   m_pullbackMaxPercent = 50.0;   // 50% máximo de retroceso
   
   // Inicializar variables
   ZeroMemory(m_currentBreakout);
   m_breakoutCount = 0;
   ZeroMemory(m_stats);
   
   m_lastDirection = TREND_NONE;
   m_lastConfidence = 0.0;
   m_divergenceDetected = false;
   
   // Handles
   m_atrHandle = INVALID_HANDLE;
   m_volumeHandle = INVALID_HANDLE;
   m_momentumHandle = INVALID_HANDLE;
   m_rsiHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
// Destructor línea 195-205
CBreakoutDetector::~CBreakoutDetector() {
    if(m_showVisual) {
        ObjectsDeleteAll(0, m_prefix);
    }
    
    // Liberar handles
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    //  /* patched */  más liberaciones  /* patched */ 
    
    Cleanup(); // ¡DUPLICADO! Ya se liberaron arriba
}

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
bool CBreakoutDetector::Init(ENUM_TIMEFRAMES timeframe, bool showVisual = true) {
   m_timeframe = timeframe;
   m_showVisual = showVisual;
   
   // CORRECCIÓN: Inicializar todos los handles como inválidos primero
   m_atrHandle = INVALID_HANDLE;
   m_volumeHandle = INVALID_HANDLE;
   m_momentumHandle = INVALID_HANDLE;
   m_rsiHandle = INVALID_HANDLE;
   
   // Crear indicadores con manejo de errores individual
   m_atrHandle = iATR(Symbol(), m_timeframe, 14);
   if(m_atrHandle==INVALID_HANDLE) m_atrHandle = iATR(Symbol(), PERIOD_CURRENT, 14);
   if(m_atrHandle == INVALID_HANDLE) {
      Print("BreakoutDetector: Error creando indicador ATR");
      Cleanup();
      return false;
   }
   
   m_volumeHandle = iVolumes(Symbol(), m_timeframe, VOLUME_TICK);
   if(m_volumeHandle==INVALID_HANDLE) m_volumeHandle = iVolumes(Symbol(), PERIOD_CURRENT, VOLUME_TICK);
   if(m_volumeHandle == INVALID_HANDLE) {
      Print("BreakoutDetector: Error creando indicador Volumes");
      Cleanup();
      return false;
   }
   
   m_momentumHandle = iMomentum(Symbol(), m_timeframe, 14, PRICE_CLOSE);
   if(m_momentumHandle==INVALID_HANDLE) m_momentumHandle = iMomentum(Symbol(), PERIOD_CURRENT, 14, PRICE_CLOSE);
   if(m_momentumHandle == INVALID_HANDLE) {
      Print("BreakoutDetector: Error creando indicador Momentum");
      Cleanup();
      return false;
   }
   
   m_rsiHandle = iRSI(Symbol(), m_timeframe, 14, PRICE_CLOSE);
   if(m_rsiHandle==INVALID_HANDLE) m_rsiHandle = iRSI(Symbol(), PERIOD_CURRENT, 14, PRICE_CLOSE);
   if(m_rsiHandle == INVALID_HANDLE) {
      Print("BreakoutDetector: Error creando indicador RSI");
      Cleanup();
      return false;
   }
   
   // CORRECCIÓN: Verificar que los indicadores estén calculados
   double testBuffer[1];
   bool indicatorsReady = true;
   
   if(CopyBuffer(m_atrHandle, 0, 0, 1, testBuffer) <= 0) {
      Print("BreakoutDetector: ATR no está listo");
      indicatorsReady = false;
   }
   
   if(CopyBuffer(m_volumeHandle, 0, 0, 1, testBuffer) <= 0) {
      Print("BreakoutDetector: Volume no está listo");
      indicatorsReady = false;
   }
   
   if(CopyBuffer(m_momentumHandle, 0, 0, 1, testBuffer) <= 0) {
      Print("BreakoutDetector: Momentum no está listo");
      indicatorsReady = false;
   }
   
   if(CopyBuffer(m_rsiHandle, 0, 0, 1, testBuffer) <= 0) {
      Print("BreakoutDetector: RSI no está listo");
      indicatorsReady = false;
   }
   
   if(!indicatorsReady) {
      Print("BreakoutDetector: indicadores aún no tienen datos – inicialización diferida");
      // Continuamos sin abortar; los buffers se llenarán tras los primeros ticks
   }
   
   m_initialized = true;
   Print("BreakoutDetector inicializado correctamente - Detección de rupturas activada");
   return true;
}


ENUM_TREND_DIRECTION CBreakoutDetector::GetImmediateDirection() {
    if(!m_initialized) return TREND_NONE;
    
    // CORRECCIÓN: Tiempo dinámico según timeframe (REDUCIDO para mayor precisión)
    int maxBarsValid = 0;
    switch(m_timeframe) {
        case PERIOD_M1:  maxBarsValid = 30; break;  // Reducido de 60 a 30 (30 min)
        case PERIOD_M5:  maxBarsValid = 6; break;   // Reducido de 12 a 6 (30 min)
        case PERIOD_M15: maxBarsValid = 4; break;   // Reducido de 8 a 4 (1 hora)
        case PERIOD_M30: maxBarsValid = 3; break;   // Reducido de 8 a 3 (1.5 horas)
        case PERIOD_H1:  maxBarsValid = 2; break;   // Reducido de 6 a 2 (2 horas)
        case PERIOD_H4:  maxBarsValid = 1; break;   // Reducido de 6 a 1 (4 horas)
        case PERIOD_D1:  maxBarsValid = 1; break;   // Reducido de 5 a 1 (1 día)
        default: maxBarsValid = 2;
    }
    
    // Verificar breakout activo
    if(m_currentBreakout.confirmed) {
        int barsSinceBreakout = Bars(Symbol(), m_timeframe, m_currentBreakout.time, TimeCurrent());
        
        // NUEVO: Análisis de retest
        bool retestSuccessful = false;
        if(barsSinceBreakout >= 2) {
            MqlRates rates[];
            ArraySetAsSeries(rates, true);
            
            int copied = CopyRates(Symbol(), m_timeframe, 0, barsSinceBreakout + 1, rates);
            if(copied > 0) {
                // Tolerancia del 0.2% para retest
                double tolerance = 0.002;
                
                if(m_currentBreakout.type == BREAKOUT_RESISTANCE) {
                    // Buscar retest de resistencia convertida en soporte
                    for(int i = 1; i < MathMin(barsSinceBreakout, copied); i++) {
                        if(rates[i].low <= m_currentBreakout.breakoutPrice * (1 + tolerance) && 
                           rates[i].close > m_currentBreakout.breakoutPrice) {
                            retestSuccessful = true;
                            break;
                        }
                    }
                } else if(m_currentBreakout.type == BREAKOUT_SUPPORT) {
                    // Buscar retest de soporte convertido en resistencia
                    for(int i = 1; i < MathMin(barsSinceBreakout, copied); i++) {
                        if(rates[i].high >= m_currentBreakout.breakoutPrice * (1 - tolerance) && 
                           rates[i].close < m_currentBreakout.breakoutPrice) {
                            retestSuccessful = true;
                            break;
                        }
                    }
                }
            }
        }
        
        // Extender validez si hubo retest exitoso
        int effectiveMaxBars = retestSuccessful ? maxBarsValid * 2 : maxBarsValid;
        
        if(barsSinceBreakout <= effectiveMaxBars) {
            if(m_currentBreakout.type == BREAKOUT_RESISTANCE) {
                m_lastDirection = TREND_UP;
                return TREND_UP;
            } else if(m_currentBreakout.type == BREAKOUT_SUPPORT) {
                m_lastDirection = TREND_DOWN;
                return TREND_DOWN;
            }
        }
    }
    
    // NUEVO: Análisis mejorado sin breakout activo
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), m_timeframe, 0, 20, rates) < 20) {
        return TREND_NONE;
    }
    
    // Obtener ATR para análisis
    double atr = 0;
    double atrBuffer[1];
    if(m_atrHandle != INVALID_HANDLE && CopyBuffer(m_atrHandle, 0, 0, 1, atrBuffer) > 0) {
        atr = atrBuffer[0];
    } else {
        atr = 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    }
    
    // NUEVO: Análisis de estructura de mercado mejorado
    int higherHighs = 0, lowerLows = 0;
    int higherLows = 0, lowerHighs = 0;
    
    // Buscar pivotes
    for(int i = 2; i < 18; i++) {
        // Detectar pivot high
        if(rates[i].high > rates[i-1].high && rates[i].high > rates[i+1].high &&
           rates[i].high > rates[i-2].high && rates[i].high > rates[i+2].high) {
            
            // Comparar con pivotes anteriores
            for(int j = i + 2; j < 18; j++) {
                if(rates[j].high > rates[j-1].high && rates[j].high > rates[j+1].high) {
                    if(rates[i].high > rates[j].high) higherHighs++;
                    else lowerHighs++;
                    break;
                }
            }
        }
        
        // Detectar pivot low
        if(rates[i].low < rates[i-1].low && rates[i].low < rates[i+1].low &&
           rates[i].low < rates[i-2].low && rates[i].low < rates[i+2].low) {
            
            // Comparar con pivotes anteriores
            for(int j = i + 2; j < 18; j++) {
                if(rates[j].low < rates[j-1].low && rates[j].low < rates[j+1].low) {
                    if(rates[i].low < rates[j].low) lowerLows++;
                    else higherLows++;
                    break;
                }
            }
        }
    }
    
    // NUEVO: Análisis de momentum con RSI
    double rsi = 50.0;
    double rsiBuffer[1];
    if(m_rsiHandle != INVALID_HANDLE && CopyBuffer(m_rsiHandle, 0, 0, 1, rsiBuffer) > 0) {
        rsi = rsiBuffer[0];
    }
    
    // Decisión basada en estructura y momentum
    int bullishScore = higherHighs + higherLows;
    int bearishScore = lowerLows + lowerHighs;
    
    // Ajustar por RSI
    if(rsi > 60) bullishScore += 2;
    else if(rsi > 55) bullishScore += 1;
    else if(rsi < 40) bearishScore += 2;
    else if(rsi < 45) bearishScore += 1;
    
    // Decisión final
    if(bullishScore > bearishScore + 1) {
        m_lastDirection = TREND_UP;
        return TREND_UP;
    } else if(bearishScore > bullishScore + 1) {
        m_lastDirection = TREND_DOWN;
        return TREND_DOWN;
    }
    
    return TREND_NONE;
}

//+------------------------------------------------------------------+
//| Obtener confianza de la dirección                               |
//+------------------------------------------------------------------+
double CBreakoutDetector::GetDirectionConfidence() {
   if(!m_initialized) return 0.0;
   
   double confidence = 30.0; // Base
   
   // Si hay breakout confirmado
   if(m_currentBreakout.confirmed) {
      confidence = 60.0;
      
      // Bonus por fuerza del breakout
      switch(m_currentBreakout.strength) {
         case BREAKOUT_EXPLOSIVE:
            confidence += 30.0;
            break;
         case BREAKOUT_STRONG:
            confidence += 20.0;
            break;
         case BREAKOUT_MODERATE:
            confidence += 10.0;
            break;
         default:
            confidence += 5.0;
      }
      
      // Bonus por volumen
      if(m_currentBreakout.volume > 2.0) {
         confidence += 10.0;
      }
      
      // Penalización por pullback profundo
      if(m_currentBreakout.hadPullback && m_currentBreakout.pullbackDepth > 30.0) {
         confidence -= 15.0;
      }
   } else {
      // Análisis general de momentum
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(Symbol(), m_timeframe, 0, 20, rates) >= 20) {
         double momentum = MathAbs(CalculateMomentum(rates, 0, 10));
         confidence += momentum * 50.0; // Hasta 50 puntos extra
         
         // RSI para confirmar
         double rsi[];
         ArraySetAsSeries(rsi, true);
         if(CopyBuffer(m_rsiHandle, 0, 0, 1, rsi) > 0) {
            if((m_lastDirection == TREND_UP && rsi[0] > 60) ||
               (m_lastDirection == TREND_DOWN && rsi[0] < 40)) {
               confidence += 10.0;
            }
         }
      }
   }
   
   return MathMin(100.0, MathMax(0.0, confidence));
}

//+------------------------------------------------------------------+
//| Analizar breakouts en niveles S/R                               |
//+------------------------------------------------------------------+
bool CBreakoutDetector::AnalyzeBreakouts(SRLevel &levels[], int levelCount) {
   if(!m_initialized || levelCount <= 0) return false;
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), m_timeframe, 0, 100, rates);
   
   if(copied < 50) return false;
   
   // Detectar nuevos breakouts
   bool newBreakoutDetected = DetectBreakout(rates, copied, levels, levelCount);
   
   // Validar breakout actual si existe
   if(m_currentBreakout.time > 0 && !m_currentBreakout.confirmed) {
      int barsSince = Bars(Symbol(), m_timeframe, m_currentBreakout.time, TimeCurrent());
      
      if(barsSince >= m_confirmationBars) {
         if(ValidateBreakout(m_currentBreakout, rates, 0)) {
            m_currentBreakout.confirmed = true;
            m_currentBreakout.confirmationBars = barsSince;
            
            Print(">>> BREAKOUT CONFIRMADO: ", 
                  EnumToString(m_currentBreakout.type), 
                  " @ ", DoubleToString(m_currentBreakout.breakoutPrice, _Digits));
                  
            // Agregar a historial
            if(m_breakoutCount < 10) {
               m_recentBreakouts[m_breakoutCount] = m_currentBreakout;
               m_breakoutCount++;
            }
            
            // Actualizar estadísticas
            UpdateBreakoutStats();
            
            // Visualizar
            if(m_showVisual) {
               DrawBreakoutZone(m_currentBreakout);
               DrawBreakoutArrow(m_currentBreakout);
            }
         } else if(IsFalseBreakout(m_currentBreakout, rates, 0)) {
            Print(">>> BREAKOUT FALSO detectado");
            m_currentBreakout.type = BREAKOUT_FALSE;
            m_stats.falseBreakouts++;
            ZeroMemory(m_currentBreakout);
         }
      }
   }
   
   // Verificar si el breakout actual sigue siendo válido
   if(m_currentBreakout.confirmed) {
      int age = Bars(Symbol(), m_timeframe, m_currentBreakout.time, TimeCurrent());
      
      // Invalidar después de 20 barras
      if(age > 20) {
         Print("Breakout expirado después de ", age, " barras");
         ZeroMemory(m_currentBreakout);
      }
   }
   
   // Actualizar visualización
   if(m_showVisual) {
      UpdateVisual();
   }
   
   return newBreakoutDetected || m_currentBreakout.confirmed;
}

//+------------------------------------------------------------------+
//| Detectar breakout en niveles                                    |
//+------------------------------------------------------------------+
bool CBreakoutDetector::DetectBreakout(const MqlRates &rates[], int count, SRLevel &levels[], int levelCount) {
   if(m_currentBreakout.time > 0 && !m_currentBreakout.confirmed) {
      return false; // Ya hay un breakout pendiente de confirmación
   }
   
   double atr = 0;
   double atrBuffer[1];
   if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuffer) > 0) {
      atr = atrBuffer[0];
   }
   
   if(atr <= 0) return false;
   
   // Buscar breakouts en las últimas 3 barras
   for(int bar = 0; bar < 3 && bar < count; bar++) {
      // Verificar cada nivel
      for(int i = 0; i < levelCount; i++) {
// if(!levels[i].active) continue;
         
         double levelPrice = levels[i].price;
         double breakoutDistance = atr * m_minBreakoutPercent;
         
         // Verificar breakout de resistencia
         if(levels[i].type == SR_RESISTANCE) {
            // La barra anterior estaba debajo y la actual cerró arriba
            if(bar < count - 1 && 
               rates[bar + 1].close < levelPrice && 
               rates[bar].close > levelPrice + breakoutDistance) {
               
               // Verificar volumen
               if(CheckVolumeSpike(rates, bar, m_volumeThreshold)) {
                  // Crear señal de breakout
                  ZeroMemory(m_currentBreakout);
                  m_currentBreakout.time = rates[bar].time;
                  m_currentBreakout.breakoutPrice = levelPrice;
                  m_currentBreakout.type = BREAKOUT_RESISTANCE;
                  m_currentBreakout.volume = (double)rates[bar].tick_volume / GetAverageVolume(rates, 20);
                  m_currentBreakout.momentum = CalculateMomentum(rates, bar, 5);
                  m_currentBreakout.srLevelId = levels[i].id;
                  m_currentBreakout.targetPrice = levelPrice + atr * 2.0;
                  m_currentBreakout.stopPrice = levelPrice - atr * 0.5;
                  
                  // Calcular fuerza
                  m_currentBreakout.strength = CalculateBreakoutStrength(
                     rates[bar].close - levelPrice, 
                     m_currentBreakout.volume, 
                     atr
                  );
                  
                  Print("Posible BREAKOUT ALCISTA detectado en nivel #", levels[i].id);
                  return true;
               }
            }
         }
         // Verificar breakout de soporte
         else if(levels[i].type == SR_SUPPORT) {
            // La barra anterior estaba arriba y la actual cerró abajo
            if(bar < count - 1 && 
               rates[bar + 1].close > levelPrice && 
               rates[bar].close < levelPrice - breakoutDistance) {
               
               // Verificar volumen
               if(CheckVolumeSpike(rates, bar, m_volumeThreshold)) {
                  // Crear señal de breakout
                  ZeroMemory(m_currentBreakout);
                  m_currentBreakout.time = rates[bar].time;
                  m_currentBreakout.breakoutPrice = levelPrice;
                  m_currentBreakout.type = BREAKOUT_SUPPORT;
                  m_currentBreakout.volume = (double)rates[bar].tick_volume / GetAverageVolume(rates, 20);
                  m_currentBreakout.momentum = CalculateMomentum(rates, bar, 5);
                  m_currentBreakout.srLevelId = levels[i].id;
                  m_currentBreakout.targetPrice = levelPrice - atr * 2.0;
                  m_currentBreakout.stopPrice = levelPrice + atr * 0.5;
                  
                  // Calcular fuerza
                  m_currentBreakout.strength = CalculateBreakoutStrength(
                     levelPrice - rates[bar].close, 
                     m_currentBreakout.volume, 
                     atr
                  );
                  
                  Print("Posible BREAKOUT BAJISTA detectado en nivel #", levels[i].id);
                  return true;
               }
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calcular fuerza del breakout                                    |
//+------------------------------------------------------------------+
ENUM_BREAKOUT_STRENGTH CBreakoutDetector::CalculateBreakoutStrength(double priceMove, double volume, double atr) {
   double score = 0;
   
   // Factor 1: Magnitud del movimiento (0-40 puntos)
   double moveRatio = priceMove / atr;
   if(moveRatio > 1.0) score += 40;
   else if(moveRatio > 0.5) score += 30;
   else if(moveRatio > 0.25) score += 20;
   else score += 10;
   
   // Factor 2: Volumen (0-40 puntos)
   if(volume > 3.0) score += 40;
   else if(volume > 2.0) score += 30;
   else if(volume > 1.5) score += 20;
   else score += 10;
   
   // Factor 3: Momentum (0-20 puntos)
   double momentum[];
   ArraySetAsSeries(momentum, true);
   if(CopyBuffer(m_momentumHandle, 0, 0, 1, momentum) > 0) {
      double momValue = MathAbs(momentum[0] - 100.0);
      if(momValue > 5.0) score += 20;
      else if(momValue > 3.0) score += 15;
      else if(momValue > 1.0) score += 10;
      else score += 5;
   }
   
   // Clasificar fuerza
   if(score >= 80) return BREAKOUT_EXPLOSIVE;
   else if(score >= 60) return BREAKOUT_STRONG;
   else if(score >= 40) return BREAKOUT_MODERATE;
   else return BREAKOUT_WEAK;
}

//+------------------------------------------------------------------+
//| Validar breakout                                                |
//+------------------------------------------------------------------+
bool CBreakoutDetector::ValidateBreakout(const BreakoutSignal &signal, const MqlRates &rates[], int currentBar) {
   // El precio debe mantenerse del lado correcto del nivel
   if(signal.type == BREAKOUT_RESISTANCE) {
      // Para breakout alcista, el precio debe mantenerse arriba
      if(rates[currentBar].close <= signal.breakoutPrice) {
         return false;
      }
      
      // Verificar pullback
      double pullback = (signal.breakoutPrice - rates[currentBar].low) / 
                       (rates[currentBar].high - signal.breakoutPrice) * 100;
      
      if(pullback > m_pullbackMaxPercent) {
         return false;
      }
   } else if(signal.type == BREAKOUT_SUPPORT) {
      // Para breakout bajista, el precio debe mantenerse abajo
      if(rates[currentBar].close >= signal.breakoutPrice) {
         return false;
      }
      
      // Verificar pullback
      double pullback = (rates[currentBar].high - signal.breakoutPrice) / 
                       (signal.breakoutPrice - rates[currentBar].low) * 100;
      
      if(pullback > m_pullbackMaxPercent) {
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calcular momentum                                                |
//+------------------------------------------------------------------+
double CBreakoutDetector::CalculateMomentum(const MqlRates &rates[], int startBar, int period) {
   if(startBar + period >= ArraySize(rates)) return 0.0;
   
   double priceChange = (rates[startBar].close - rates[startBar + period].close) / rates[startBar + period].close;
   return priceChange;
}

//+------------------------------------------------------------------+
//| Verificar spike de volumen                                       |
//+------------------------------------------------------------------+
bool CBreakoutDetector::CheckVolumeSpike(const MqlRates &rates[], int bar, double threshold) {
   if(bar >= ArraySize(rates)) return false;
   
   double avgVolume = GetAverageVolume(rates, 20);
   if(avgVolume <= 0) return true; // Si no hay datos, aceptar
   
   double currentVolume = (double)rates[bar].tick_volume;
   return (currentVolume / avgVolume) >= threshold;
}

//+------------------------------------------------------------------+
//| Detectar breakout falso                                          |
//+------------------------------------------------------------------+
bool CBreakoutDetector::IsFalseBreakout(const BreakoutSignal &signal, const MqlRates &rates[], int currentBar) {
   // El precio volvió al lado incorrecto del nivel
   if(signal.type == BREAKOUT_RESISTANCE) {
      return rates[currentBar].close < signal.breakoutPrice;
   } else if(signal.type == BREAKOUT_SUPPORT) {
      return rates[currentBar].close > signal.breakoutPrice;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Obtener volumen promedio                                        |
//+------------------------------------------------------------------+
double CBreakoutDetector::GetAverageVolume(const MqlRates &rates[], int period) {
   double sum = 0;
   int count = 0;
   
   for(int i = 0; i < period && i < ArraySize(rates); i++) {
      sum += (double)rates[i].tick_volume;
      count++;
   }
   
   return count > 0 ? sum / count : 0;
}

//+------------------------------------------------------------------+
//| Actualizar estadísticas                                          |
//+------------------------------------------------------------------+
void CBreakoutDetector::UpdateBreakoutStats() {
   m_stats.totalBreakouts++;
   
   if(m_currentBreakout.confirmed) {
      m_stats.successfulBreakouts++;
   }
   
   // Calcular tasa de éxito
   if(m_stats.totalBreakouts > 0) {
      m_stats.successRate = (double)m_stats.successfulBreakouts / m_stats.totalBreakouts * 100.0;
   }
   
   // Actualizar promedios
   m_stats.avgMomentum = (m_stats.avgMomentum * (m_stats.totalBreakouts - 1) + 
                          m_currentBreakout.momentum) / m_stats.totalBreakouts;
   
   m_stats.avgVolume = (m_stats.avgVolume * (m_stats.totalBreakouts - 1) + 
                       m_currentBreakout.volume) / m_stats.totalBreakouts;
}

//+------------------------------------------------------------------+
//| Dibujar zona de breakout                                        |
//+------------------------------------------------------------------+
void CBreakoutDetector::DrawBreakoutZone(const BreakoutSignal &signal) {
   if(!m_showVisual) return;
   
   string name = m_prefix + "ZONE_" + TimeToString(signal.time);
   datetime endTime = signal.time + PeriodSeconds(m_timeframe) * 10;
   
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, signal.time, signal.breakoutPrice, 
                endTime, signal.targetPrice);
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, GetBreakoutColor(signal.type, signal.strength));
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Dibujar flecha de breakout                                      |
//+------------------------------------------------------------------+
void CBreakoutDetector::DrawBreakoutArrow(const BreakoutSignal &signal) {
   if(!m_showVisual) return;
   
   string name = m_prefix + "ARROW_" + TimeToString(signal.time);
   
   ObjectCreate(0, name, OBJ_ARROW, 0, signal.time, signal.breakoutPrice);
   
   if(signal.type == BREAKOUT_RESISTANCE) {
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233); // Flecha arriba
   } else {
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234); // Flecha abajo
   }
   
   ObjectSetInteger(0, name, OBJPROP_COLOR, GetBreakoutColor(signal.type, signal.strength));
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
}

//+------------------------------------------------------------------+
//| Obtener color según tipo y fuerza                               |
//+------------------------------------------------------------------+
color CBreakoutDetector::GetBreakoutColor(ENUM_BREAKOUT_TYPE type, ENUM_BREAKOUT_STRENGTH strength) {
   if(type == BREAKOUT_RESISTANCE) {
      switch(strength) {
         case BREAKOUT_EXPLOSIVE: return clrLime;
         case BREAKOUT_STRONG: return clrGreen;
         case BREAKOUT_MODERATE: return clrMediumSeaGreen;
         default: return clrDarkGreen;
      }
   } else if(type == BREAKOUT_SUPPORT) {
      switch(strength) {
         case BREAKOUT_EXPLOSIVE: return clrRed;
         case BREAKOUT_STRONG: return clrCrimson;
         case BREAKOUT_MODERATE: return clrIndianRed;
         default: return clrDarkRed;
      }
   }
   
   return clrGray;
}

//+------------------------------------------------------------------+
//| Actualizar visualización                                        |
//+------------------------------------------------------------------+
void CBreakoutDetector::UpdateVisual() {
   if(!m_showVisual) return;
   
   // Limpiar objetos antiguos
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, m_prefix) == 0) {
         datetime objTime = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);
         if(TimeCurrent() - objTime > 86400) { // Más de 24 horas
            ObjectDelete(0, name);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Imprimir análisis de breakout                                   |
//+------------------------------------------------------------------+
void CBreakoutDetector::PrintBreakoutAnalysis() {
   Print("=== ANÁLISIS DE BREAKOUT ===");
   
   if(m_currentBreakout.confirmed) {
      Print("Breakout activo: ", EnumToString(m_currentBreakout.type));
      Print("Precio: ", DoubleToString(m_currentBreakout.breakoutPrice, _Digits));
      Print("Fuerza: ", EnumToString(m_currentBreakout.strength));
      Print("Volumen: ", DoubleToString(m_currentBreakout.volume, 2), "x promedio");
      Print("Momentum: ", DoubleToString(m_currentBreakout.momentum * 100, 2), "%");
      Print("Target: ", DoubleToString(m_currentBreakout.targetPrice, _Digits));
   } else {
      Print("Sin breakout activo");
   }
   
   Print("Estadísticas:");
   Print("- Total breakouts: ", m_stats.totalBreakouts);
   Print("- Exitosos: ", m_stats.successfulBreakouts);
   Print("- Falsos: ", m_stats.falseBreakouts);
   Print("- Tasa de éxito: ", DoubleToString(m_stats.successRate, 1), "%");
   
   Print("===========================");
}

#endif // __BREAKOUTDETECTOR_FIXED_MQH__