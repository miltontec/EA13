#ifndef __INSTITUTIONALPLANFINDER_FIXED_MQH__
#define __INSTITUTIONALPLANFINDER_FIXED_MQH__

//+------------------------------------------------------------------+
//|                                      InstitutionalPlanFinder.mqh |
//|                        Copyright 2025, Trading Strategy Developer |
//|                        DETECTOR DE PLANES INSTITUCIONALES         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Strategy Developer"
#property link      "https://www.domain.com"

#include <AccumulationZones.mqh>
#include <PatternMemory.mqh>

//+------------------------------------------------------------------+
//| ENUMERACIONES Y ESTRUCTURAS                                      |
//+------------------------------------------------------------------+

enum ENUM_INSTITUTIONAL_PHASE {
   PHASE_NONE,
   PHASE_ACCUMULATION,    // Institucionales acumulando
   PHASE_MARKUP,          // Fase de impulso alcista
   PHASE_DISTRIBUTION,    // Institucionales distribuyendo
   PHASE_MARKDOWN         // Fase de impulso bajista
};

enum ENUM_VOLUME_PROFILE {
   VOLUME_LOW,
   VOLUME_NORMAL,
   VOLUME_HIGH,
   VOLUME_CLIMACTIC,      // Volumen climático
   VOLUME_EXHAUSTION      // Volumen de agotamiento
};

enum ENUM_MARKET_STRUCTURE {
   STRUCTURE_RANGE,       // Rango/consolidación
   STRUCTURE_TREND_UP,    // Tendencia alcista
   STRUCTURE_TREND_DOWN,  // Tendencia bajista
   STRUCTURE_REVERSAL     // Reversión en proceso
};

struct InstitutionalFootprint {
   datetime        time;
   double          priceLevel;
   ENUM_INSTITUTIONAL_PHASE phase;
   double          volumeIntensity;
   double          smartMoneyIndex;
   bool            confirmed;
   int             duration;          // Duración en barras
   double          priceRangePercent; // Rango de precio en %
   bool            hasVolumeAnomaly;
   double          buyPressure;       // Presión compradora (0-100)
   double          sellPressure;      // Presión vendedora (0-100)
   ENUM_MARKET_STRUCTURE structure;
   double          confidence;        // Confianza de la detección
};

struct VolumeNode {
   double          price;
   double          volume;
   double          buyVolume;
   double          sellVolume;
   bool            isHVN;            // High Volume Node
   bool            isLVN;            // Low Volume Node
   bool            isPOC;            // Point of Control
};

//+------------------------------------------------------------------+
//| CLASE PRINCIPAL - BUSCADOR DE PLANES INSTITUCIONALES            |
//+------------------------------------------------------------------+

class CInstitutionalPlanFinder {
private:
   // Configuración
   ENUM_TIMEFRAMES m_timeframe;
   bool            m_showVisual;
   bool            m_initialized;
   string          m_prefix;
   
   // Parámetros de detección
   double          m_minVolumeRatio;      // Ratio mínimo de volumen
   int             m_minPhaseDuration;    // Duración mínima de fase
   double          m_smartMoneyThreshold; // Umbral para Smart Money
   double          m_volumeProfileDepth;  // Profundidad del perfil de volumen
   
   // Estado actual
   InstitutionalFootprint m_currentFootprint;
   InstitutionalFootprint m_recentFootprints[10];
   int             m_footprintCount;
   ENUM_INSTITUTIONAL_PHASE m_currentPhase;
   
   // Variables de análisis
   ENUM_TREND_DIRECTION m_lastDirection;
   double          m_lastConfidence;
   VolumeNode      m_volumeProfile[100];
   int             m_profileNodeCount;
   
   // Handles de indicadores
   int             m_volumeHandle;
   int             m_obvHandle;      // On Balance Volume
   int             m_mfiHandle;      // Money Flow Index
   int             m_adHandle;       // Accumulation/Distribution
   int             m_cmfHandle;      // Chaikin Money Flow
   
   // Métodos privados de análisis
   ENUM_INSTITUTIONAL_PHASE DetectCurrentPhase(const MqlRates &rates[], int count);
   double          CalculateSmartMoneyIndex(const MqlRates &rates[], int startBar, int period);
   bool            DetectVolumeAnomaly(const MqlRates &rates[], int bar);
   void            BuildVolumeProfile(const MqlRates &rates[], int count);
   double          CalculateBuySellPressure(const MqlRates &rates[], int bar, double &buy, double &sell);
   ENUM_MARKET_STRUCTURE AnalyzeMarketStructure(const MqlRates &rates[], int count);
   bool            IsAccumulationPattern(const MqlRates &rates[], int startBar, int count);
   bool            IsDistributionPattern(const MqlRates &rates[], int startBar, int count);
   double          GetVolumeAtPrice(double price, double tolerance);
   bool            DetectWyckoffPattern(const MqlRates &rates[], int count);
   bool            DetectStopHunt(const MqlRates &rates[], int bar);
   double          CalculateVolumeWeightedPrice(const MqlRates &rates[], int period);
   
   // Métodos de visualización
   void            DrawInstitutionalZone(const InstitutionalFootprint &footprint);
   void            DrawVolumeProfile();
   color           GetPhaseColor(ENUM_INSTITUTIONAL_PHASE phase, double confidence);
   
public:
   CInstitutionalPlanFinder();
   ~CInstitutionalPlanFinder();
   
   // Métodos principales
   bool            Init(ENUM_TIMEFRAMES timeframe, bool showVisual = true);
   
   // MÉTODOS CLAVE PARA SISTEMA DE VOTACIÓN
   ENUM_TREND_DIRECTION GetImmediateDirection();
   double          GetDirectionConfidence();
   
   // Métodos de análisis
   bool            AnalyzeInstitutionalActivity(AccumulationZone &zones[], int zoneCount);
   InstitutionalFootprint GetCurrentFootprint() { return m_currentFootprint; }
   ENUM_INSTITUTIONAL_PHASE GetCurrentPhase() { return m_currentPhase; }
   
   // Métodos de configuración
   void            SetMinVolumeRatio(double ratio) { m_minVolumeRatio = ratio; }
   void            SetMinPhaseDuration(int bars) { m_minPhaseDuration = bars; }
   void            SetSmartMoneyThreshold(double threshold) { m_smartMoneyThreshold = threshold; }
   
   // Métodos de información
   void            PrintInstitutionalAnalysis();
   void            UpdateVisual();
   bool            GetVolumeProfile(VolumeNode &nodes[], int &nodeCount);
   double          GetPointOfControl();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CInstitutionalPlanFinder::CInstitutionalPlanFinder() {
   m_timeframe = PERIOD_CURRENT;
   m_showVisual = true;
   m_initialized = false;
   m_prefix = "INST_";
   
   // Parámetros por defecto
   m_minVolumeRatio = 1.5;        // 50% más volumen que promedio
   m_minPhaseDuration = 10;       // Mínimo 10 barras
   m_smartMoneyThreshold = 60.0;  // 60% de confianza
   m_volumeProfileDepth = 50;     // 50 barras de profundidad
   
   // Inicializar variables
   ZeroMemory(m_currentFootprint);
   m_footprintCount = 0;
   m_currentPhase = PHASE_NONE;
   m_profileNodeCount = 0;
   
   m_lastDirection = TREND_NONE;
   m_lastConfidence = 0.0;
   
   // Handles
   m_volumeHandle = INVALID_HANDLE;
   m_obvHandle = INVALID_HANDLE;
   m_mfiHandle = INVALID_HANDLE;
   m_adHandle = INVALID_HANDLE;
   m_cmfHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CInstitutionalPlanFinder::~CInstitutionalPlanFinder() {
   if(m_showVisual) {
      ObjectsDeleteAll(0, m_prefix);
   }
   
   // Liberar handles
   if(m_volumeHandle != INVALID_HANDLE) IndicatorRelease(m_volumeHandle);
   if(m_obvHandle != INVALID_HANDLE) IndicatorRelease(m_obvHandle);
   if(m_mfiHandle != INVALID_HANDLE) IndicatorRelease(m_mfiHandle);
   if(m_adHandle != INVALID_HANDLE) IndicatorRelease(m_adHandle);
   if(m_cmfHandle != INVALID_HANDLE) IndicatorRelease(m_cmfHandle);
}

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::Init(ENUM_TIMEFRAMES timeframe, bool showVisual = true) {
   m_timeframe = timeframe;
   m_showVisual = showVisual;
   
   // Crear indicadores
   m_volumeHandle = iVolumes(Symbol(), m_timeframe, VOLUME_TICK);
   m_obvHandle = iOBV(Symbol(), m_timeframe, VOLUME_TICK);
   m_mfiHandle = iMFI(Symbol(), m_timeframe, 14, VOLUME_TICK);
   
   // AD y CMF requieren implementación custom o alternativas
   // Por ahora usaremos los disponibles
   
   if(m_volumeHandle == INVALID_HANDLE || m_obvHandle == INVALID_HANDLE || 
      m_mfiHandle == INVALID_HANDLE) {
      Print("InstitutionalPlanFinder: Error inicializando indicadores");
      return false;
   }
   
   m_initialized = true;
   Print("InstitutionalPlanFinder inicializado - Detección institucional activada");
   return true;
}

//+------------------------------------------------------------------+
//| MÉTODO PRINCIPAL: Obtener dirección inmediata                   |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CInstitutionalPlanFinder::GetImmediateDirection() {
    if(!m_initialized) return TREND_NONE;
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(Symbol(), m_timeframe, 0, 100, rates) < 100) {
        return TREND_NONE;
    }
    
    // Detectar fase actual con más contexto
    m_currentPhase = DetectCurrentPhase(rates, 100);
    
    // Analizar según fase Y momento dentro de la fase
    switch(m_currentPhase) {
        case PHASE_ACCUMULATION: {
            // En acumulación temprana = NEUTRAL
            // En acumulación tardía con springs = COMPRA
            
            // Buscar springs (falsos rompimientos bajistas)
            int springs = 0;
            double lowestLow = rates[0].low;
            
            for(int i = 1; i < 20; i++) {
                lowestLow = MathMin(lowestLow, rates[i].low);
            }
            
            for(int i = 0; i < 10; i++) {
                if(rates[i].low < lowestLow && rates[i].close > rates[i].open &&
                   rates[i].close > (rates[i].high + rates[i].low) / 2) {
                    springs++;
                }
            }
            
            if(springs > 0) {
                // Spring detectado = señal de compra
                m_lastDirection = TREND_UP;
                return TREND_UP;
            }
            
            // Sin springs, verificar si el volumen está aumentando en subidas
            double buyPressure, sellPressure;
            CalculateBuySellPressure(rates, 0, buyPressure, sellPressure);
            
            if(buyPressure > sellPressure * 1.5) {
                m_lastDirection = TREND_UP;
                return TREND_UP;
            }
            
            return TREND_NONE;  // Esperar confirmación
        }
        
        case PHASE_MARKUP:
            // Ya en tendencia alcista confirmada
            m_lastDirection = TREND_UP;
            return TREND_UP;
            
        case PHASE_DISTRIBUTION: {
            // Similar a acumulación pero invertido
            int upthrusts = 0;
            double highestHigh = rates[0].high;
            
            for(int i = 1; i < 20; i++) {
                highestHigh = MathMax(highestHigh, rates[i].high);
            }
            
            for(int i = 0; i < 10; i++) {
                if(rates[i].high > highestHigh && rates[i].close < rates[i].open &&
                   rates[i].close < (rates[i].high + rates[i].low) / 2) {
                    upthrusts++;
                }
            }
            
            if(upthrusts > 0) {
                m_lastDirection = TREND_DOWN;
                return TREND_DOWN;
            }
            
            return TREND_NONE;
        }
        
        case PHASE_MARKDOWN:
            m_lastDirection = TREND_DOWN;
            return TREND_DOWN;
            
        default: {
            // Sin fase clara, usar Smart Money Index
            double smartMoney = CalculateSmartMoneyIndex(rates, 0, 20);
            
            if(smartMoney > 65) {
                m_lastDirection = TREND_UP;
                return TREND_UP;
            } else if(smartMoney < 35) {
                m_lastDirection = TREND_DOWN;
                return TREND_DOWN;
            }
        }
    }
    
    return TREND_NONE;
}

//+------------------------------------------------------------------+
//| Obtener confianza de la dirección                               |
//+------------------------------------------------------------------+
double CInstitutionalPlanFinder::GetDirectionConfidence() {
   if(!m_initialized) return 0.0;
   
   double confidence = 40.0; // Base
   
   // Bonus por fase clara
   switch(m_currentPhase) {
      case PHASE_ACCUMULATION:
      case PHASE_DISTRIBUTION:
         confidence += 20.0; // Fases de preparación
         break;
         
      case PHASE_MARKUP:
      case PHASE_MARKDOWN:
         confidence += 30.0; // Fases de impulso
         break;
   }
   
   // Bonus por huella institucional confirmada
   if(m_currentFootprint.confirmed) {
      confidence += 20.0;
      
      // Extra por alta confianza en la huella
      confidence += m_currentFootprint.confidence * 0.1;
   }
   
   // Análisis de Money Flow Index
   double mfi[];
   ArraySetAsSeries(mfi, true);
   if(CopyBuffer(m_mfiHandle, 0, 0, 1, mfi) > 0) {
      if((m_lastDirection == TREND_UP && mfi[0] > 60) ||
         (m_lastDirection == TREND_DOWN && mfi[0] < 40)) {
         confidence += 10.0;
      }
   }
   
   // Penalización por estructura de mercado conflictiva
   if(m_currentFootprint.structure == STRUCTURE_REVERSAL) {
      confidence -= 15.0;
   }
   
   return MathMin(100.0, MathMax(0.0, confidence));
}

//+------------------------------------------------------------------+
//| Analizar actividad institucional                                |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::AnalyzeInstitutionalActivity(AccumulationZone &zones[], int zoneCount) {
   if(!m_initialized) return false;
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), m_timeframe, 0, 200, rates);
   
   if(copied < 100) return false;
   
   // Construir perfil de volumen
   BuildVolumeProfile(rates, copied);
   
   // Detectar fase actual
   ENUM_INSTITUTIONAL_PHASE newPhase = DetectCurrentPhase(rates, copied);
   
   // Si cambió la fase, crear nueva huella
   if(newPhase != m_currentPhase && newPhase != PHASE_NONE) {
      // Guardar huella anterior si existía
      if(m_currentFootprint.time > 0 && m_footprintCount < 10) {
         m_recentFootprints[m_footprintCount] = m_currentFootprint;
         m_footprintCount++;
      }
      
      // Crear nueva huella
      ZeroMemory(m_currentFootprint);
      m_currentFootprint.time = rates[0].time;
      m_currentFootprint.phase = newPhase;
      m_currentFootprint.priceLevel = rates[0].close;
      m_currentFootprint.smartMoneyIndex = CalculateSmartMoneyIndex(rates, 0, 20);
      m_currentFootprint.structure = AnalyzeMarketStructure(rates, 50);
      
      // Calcular presión compradora/vendedora
      CalculateBuySellPressure(rates, 0, m_currentFootprint.buyPressure, m_currentFootprint.sellPressure);
      
      // Detectar anomalías de volumen
      m_currentFootprint.hasVolumeAnomaly = false;
      for(int i = 0; i < 5; i++) {
         if(DetectVolumeAnomaly(rates, i)) {
            m_currentFootprint.hasVolumeAnomaly = true;
            break;
         }
      }
      
      Print(">>> NUEVA FASE INSTITUCIONAL DETECTADA: ", EnumToString(newPhase));
      
      m_currentPhase = newPhase;
      
      // Visualizar
      if(m_showVisual) {
         DrawInstitutionalZone(m_currentFootprint);
      }
   }
   
   // Actualizar huella actual
   if(m_currentFootprint.time > 0) {
      m_currentFootprint.duration++;
      
      // Calcular rango de precio
      double high = rates[0].high;
      double low = rates[0].low;
      int bars = MathMin(m_currentFootprint.duration, copied);
      
      for(int i = 0; i < bars; i++) {
         high = MathMax(high, rates[i].high);
         low = MathMin(low, rates[i].low);
      }
      
      if(low > 0) {
         m_currentFootprint.priceRangePercent = (high - low) / low * 100;
      }
      
      // Confirmar después de duración mínima
      if(!m_currentFootprint.confirmed && m_currentFootprint.duration >= m_minPhaseDuration) {
         if(m_currentFootprint.smartMoneyIndex > m_smartMoneyThreshold) {
            m_currentFootprint.confirmed = true;
            m_currentFootprint.confidence = m_currentFootprint.smartMoneyIndex;
            
            Print(">>> HUELLA INSTITUCIONAL CONFIRMADA");
            Print("Fase: ", EnumToString(m_currentFootprint.phase));
            Print("Smart Money Index: ", DoubleToString(m_currentFootprint.smartMoneyIndex, 1));
            Print("Presión compradora: ", DoubleToString(m_currentFootprint.buyPressure, 1), "%");
            Print("Presión vendedora: ", DoubleToString(m_currentFootprint.sellPressure, 1), "%");
         }
      }
   }
   
   // Correlacionar con zonas de acumulación
   for(int i = 0; i < zoneCount; i++) {
      if(zones[i].active && zones[i].confirmed) {
         // Si hay zona de acumulación y fase de acumulación, aumentar confianza
         if(m_currentPhase == PHASE_ACCUMULATION && zones[i].levelType == SR_SUPPORT) {
            m_currentFootprint.confidence += 10.0;
         } else if(m_currentPhase == PHASE_DISTRIBUTION && zones[i].levelType == SR_RESISTANCE) {
            m_currentFootprint.confidence += 10.0;
         }
      }
   }
   
   // Actualizar visualización
   if(m_showVisual) {
      UpdateVisual();
      DrawVolumeProfile();
   }
   
   return m_currentFootprint.confirmed;
}

//+------------------------------------------------------------------+
//| Detectar fase institucional actual                              |
//+------------------------------------------------------------------+
ENUM_INSTITUTIONAL_PHASE CInstitutionalPlanFinder::DetectCurrentPhase(const MqlRates &rates[], int count) {
   if(count < 50) return PHASE_NONE;
   
   // Detectar patrones de Wyckoff
   if(DetectWyckoffPattern(rates, count)) {
      // El patrón Wyckoff ya habrá establecido la fase
      return m_currentPhase;
   }
   
   // Análisis de estructura de mercado
   ENUM_MARKET_STRUCTURE structure = AnalyzeMarketStructure(rates, count);
   
   // Análisis de volumen y precio
   double avgVolume = 0;
   double recentVolume = 0;
   
   for(int i = 20; i < 40; i++) {
      avgVolume += (double)rates[i].tick_volume;
   }
   avgVolume /= 20;
   
   for(int i = 0; i < 10; i++) {
      recentVolume += (double)rates[i].tick_volume;
   }
   recentVolume /= 10;
   
   double volumeRatio = avgVolume > 0 ? recentVolume / avgVolume : 1.0;
   
   // Análisis de rango de precio
   double priceRange = 0;
   double avgRange = 0;
   
   for(int i = 0; i < 10; i++) {
      priceRange += rates[i].high - rates[i].low;
   }
   priceRange /= 10;
   
   for(int i = 20; i < 40; i++) {
      avgRange += rates[i].high - rates[i].low;
   }
   avgRange /= 20;
   
   double rangeRatio = avgRange > 0 ? priceRange / avgRange : 1.0;
   
   // Lógica de detección de fases
   if(structure == STRUCTURE_RANGE) {
      if(volumeRatio > m_minVolumeRatio && rangeRatio < 0.7) {
         // Alto volumen + bajo rango = Acumulación/Distribución
         if(IsAccumulationPattern(rates, 0, 20)) {
            return PHASE_ACCUMULATION;
         } else if(IsDistributionPattern(rates, 0, 20)) {
            return PHASE_DISTRIBUTION;
         }
      }
   } else if(structure == STRUCTURE_TREND_UP) {
      if(volumeRatio > 1.2 && rangeRatio > 1.2) {
         return PHASE_MARKUP;
      }
   } else if(structure == STRUCTURE_TREND_DOWN) {
      if(volumeRatio > 1.2 && rangeRatio > 1.2) {
         return PHASE_MARKDOWN;
      }
   }
   
   // Análisis adicional con OBV
   double obv[];
   ArraySetAsSeries(obv, true);
   if(CopyBuffer(m_obvHandle, 0, 0, 50, obv) >= 50) {
      // Tendencia del OBV
      double obvSlope = (obv[0] - obv[20]) / 20;
      
      if(obvSlope > 0 && structure == STRUCTURE_RANGE) {
         return PHASE_ACCUMULATION;
      } else if(obvSlope < 0 && structure == STRUCTURE_RANGE) {
         return PHASE_DISTRIBUTION;
      }
   }
   
   return PHASE_NONE;
}

//+------------------------------------------------------------------+
//| Calcular índice de Smart Money                                  |
//+------------------------------------------------------------------+
double CInstitutionalPlanFinder::CalculateSmartMoneyIndex(const MqlRates &rates[], int startBar, int period) {
   if(startBar + period > ArraySize(rates)) return 50.0;
   
   double score = 50.0; // Neutral
   
   // 1. Análisis de volumen en movimientos clave
   double upVolume = 0, downVolume = 0;
   
   for(int i = startBar; i < startBar + period; i++) {
      if(rates[i].close > rates[i].open) {
         upVolume += (double)rates[i].tick_volume;
      } else {
         downVolume += (double)rates[i].tick_volume;
      }
   }
   
   double totalVolume = upVolume + downVolume;
   if(totalVolume > 0) {
      double volumeBalance = (upVolume - downVolume) / totalVolume * 50;
      score += volumeBalance * 0.3; // 30% del peso
   }
   
   // 2. Análisis de stop hunts
   int stopHunts = 0;
   for(int i = startBar; i < startBar + period - 1; i++) {
      if(DetectStopHunt(rates, i)) {
         stopHunts++;
      }
   }
   
   if(stopHunts > 0) {
      score += 10; // Los institucionales cazan stops
   }
   
   // 3. Money Flow Index
   double mfi[];
   ArraySetAsSeries(mfi, true);
   if(CopyBuffer(m_mfiHandle, 0, startBar, 1, mfi) > 0) {
      score += (mfi[0] - 50) * 0.3; // 30% del peso
   }
   
   // 4. Análisis de gaps y ventanas
   int gaps = 0;
   for(int i = startBar + 1; i < startBar + period; i++) {
      double gapSize = MathAbs(rates[i].open - rates[i-1].close);
      double avgBody = (rates[i].high - rates[i].low + rates[i-1].high - rates[i-1].low) / 2;
      
      if(gapSize > avgBody * 0.3) {
         gaps++;
      }
   }
   
   if(gaps > 0) {
      score += gaps * 5; // Los gaps indican actividad institucional
   }
   
   return MathMin(100.0, MathMax(0.0, score));
}

//+------------------------------------------------------------------+
//| Detectar anomalía de volumen                                    |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::DetectVolumeAnomaly(const MqlRates &rates[], int bar) {
   if(bar >= ArraySize(rates) - 20) return false;
   
   // Calcular volumen promedio
   double avgVolume = 0;
   for(int i = bar + 1; i <= bar + 20; i++) {
      avgVolume += (double)rates[i].tick_volume;
   }
   avgVolume /= 20;
   
   double currentVolume = (double)rates[bar].tick_volume;
   
   // Anomalía si el volumen es 2x el promedio
   if(currentVolume > avgVolume * 2.0) {
      // Verificar contexto del precio
      double priceMove = MathAbs(rates[bar].close - rates[bar].open);
      double avgMove = 0;
      
      for(int i = bar + 1; i <= bar + 20; i++) {
         avgMove += MathAbs(rates[i].close - rates[i].open);
      }
      avgMove /= 20;
      
      // Volumen alto + movimiento pequeño = Anomalía institucional
      if(priceMove < avgMove * 0.5) {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Construir perfil de volumen                                     |
//+------------------------------------------------------------------+
void CInstitutionalPlanFinder::BuildVolumeProfile(const MqlRates &rates[], int count) {
   m_profileNodeCount = 0;
   
   if(count < 20) return;
   
   // Encontrar rango de precio
   double highest = rates[0].high;
   double lowest = rates[0].low;
   
   int depth = (int)MathMin(m_volumeProfileDepth, count);
   
   for(int i = 1; i < depth; i++) {
      highest = MathMax(highest, rates[i].high);
      lowest = MathMin(lowest, rates[i].low);
   }
   
   double priceRange = highest - lowest;
   if(priceRange <= 0) return;
   
   // Crear 20 niveles de precio
   int levels = 20;
   double stepSize = priceRange / levels;
   
   // Inicializar nodos
   for(int i = 0; i < levels; i++) {
      m_volumeProfile[i].price = lowest + stepSize * i;
      m_volumeProfile[i].volume = 0;
      m_volumeProfile[i].buyVolume = 0;
      m_volumeProfile[i].sellVolume = 0;
      m_volumeProfile[i].isHVN = false;
      m_volumeProfile[i].isLVN = false;
      m_volumeProfile[i].isPOC = false;
   }
   
   // Acumular volumen por nivel
   for(int i = 0; i < depth; i++) {
      // Distribuir volumen de la barra en los niveles que toca
      double barHigh = rates[i].high;
      double barLow = rates[i].low;
      double barVolume = (double)rates[i].tick_volume;
      
      // Volumen comprador/vendedor estimado
      double buyVol = 0, sellVol = 0;
      if(rates[i].close > rates[i].open) {
         buyVol = barVolume * 0.6;
         sellVol = barVolume * 0.4;
      } else {
         buyVol = barVolume * 0.4;
         sellVol = barVolume * 0.6;
      }
      
      // Asignar volumen a niveles
      for(int j = 0; j < levels; j++) {
         if(m_volumeProfile[j].price >= barLow && m_volumeProfile[j].price <= barHigh) {
            m_volumeProfile[j].volume += barVolume / 4; // Distribuir equitativamente
            m_volumeProfile[j].buyVolume += buyVol / 4;
            m_volumeProfile[j].sellVolume += sellVol / 4;
         }
      }
   }
   
   // Identificar POC (Point of Control)
   double maxVolume = 0;
   int pocIndex = 0;
   
   for(int i = 0; i < levels; i++) {
      if(m_volumeProfile[i].volume > maxVolume) {
         maxVolume = m_volumeProfile[i].volume;
         pocIndex = i;
      }
   }
   
   m_volumeProfile[pocIndex].isPOC = true;
   
   // Identificar HVN y LVN
   double avgVolume = 0;
   for(int i = 0; i < levels; i++) {
      avgVolume += m_volumeProfile[i].volume;
   }
   avgVolume /= levels;
   
   for(int i = 0; i < levels; i++) {
      if(m_volumeProfile[i].volume > avgVolume * 1.5) {
         m_volumeProfile[i].isHVN = true;
      } else if(m_volumeProfile[i].volume < avgVolume * 0.5) {
         m_volumeProfile[i].isLVN = true;
      }
   }
   
   m_profileNodeCount = levels;
}

ENUM_MARKET_STRUCTURE CInstitutionalPlanFinder::AnalyzeMarketStructure(const MqlRates &rates[], int count) {
    if(count < 20) return STRUCTURE_RANGE;
    
    // Arrays para almacenar pivotes
    struct Pivot {
        double price;
        int index;
        bool isHigh;
    };
    
    Pivot pivots[];
    ArrayResize(pivots, 0);
    
    // NUEVO: Detección mejorada de pivotes con confirmación
    int lookback = 3;
    for(int i = lookback; i < count - lookback; i++) {
        // Verificar pivot high
        bool isPivotHigh = true;
        double highPrice = rates[i].high;
        
        for(int j = i - lookback; j <= i + lookback; j++) {
            if(j != i && j >= 0 && j < count) {
                if(rates[j].high >= highPrice) {
                    isPivotHigh = false;
                    break;
                }
            }
        }
        
        if(isPivotHigh) {
            int size = ArraySize(pivots);
            ArrayResize(pivots, size + 1);
            pivots[size].price = highPrice;
            pivots[size].index = i;
            pivots[size].isHigh = true;
        }
        
        // Verificar pivot low
        bool isPivotLow = true;
        double lowPrice = rates[i].low;
        
        for(int j = i - lookback; j <= i + lookback; j++) {
            if(j != i && j >= 0 && j < count) {
                if(rates[j].low <= lowPrice) {
                    isPivotLow = false;
                    break;
                }
            }
        }
        
        if(isPivotLow) {
            int size = ArraySize(pivots);
            ArrayResize(pivots, size + 1);
            pivots[size].price = lowPrice;
            pivots[size].index = i;
            pivots[size].isHigh = false;
        }
    }
    
    // Necesitamos al menos 4 pivotes para análisis
    if(ArraySize(pivots) < 4) return STRUCTURE_RANGE;
    
    // NUEVO: Análisis de tendencia basado en pivotes
    int higherHighs = 0, lowerLows = 0;
    int higherLows = 0, lowerHighs = 0;
    
    // Separar highs y lows
    double highs[], lows[];
    ArrayResize(highs, 0);
    ArrayResize(lows, 0);
    
    for(int i = 0; i < ArraySize(pivots); i++) {
        if(pivots[i].isHigh) {
            ArrayResize(highs, ArraySize(highs) + 1);
            highs[ArraySize(highs) - 1] = pivots[i].price;
        } else {
            ArrayResize(lows, ArraySize(lows) + 1);
            lows[ArraySize(lows) - 1] = pivots[i].price;
        }
    }
    
    // Analizar secuencia de highs
    for(int i = 1; i < ArraySize(highs); i++) {
        if(highs[i] > highs[i-1]) higherHighs++;
        else lowerHighs++;
    }
    
    // Analizar secuencia de lows
    for(int i = 1; i < ArraySize(lows); i++) {
        if(lows[i] > lows[i-1]) higherLows++;
        else lowerLows++;
    }
    
    // NUEVO: Lógica de decisión mejorada
    int bullishPoints = higherHighs + higherLows;
    int bearishPoints = lowerHighs + lowerLows;
    int totalPoints = bullishPoints + bearishPoints;
    
    if(totalPoints == 0) return STRUCTURE_RANGE;
    
    // Calcular porcentaje de sesgo
    double bullishPercent = (double)bullishPoints / totalPoints * 100;
    double bearishPercent = (double)bearishPoints / totalPoints * 100;
    
    // Tendencia alcista clara: HH + HL dominantes
    if(bullishPercent >= 65 && higherHighs > 0 && higherLows > 0) {
        return STRUCTURE_TREND_UP;
    }
    // Tendencia bajista clara: LH + LL dominantes
    else if(bearishPercent >= 65 && lowerHighs > 0 && lowerLows > 0) {
        return STRUCTURE_TREND_DOWN;
    }
    // Posible reversión
    else if((higherHighs > 0 && lowerLows > 0) || 
            (lowerHighs > 0 && higherLows > 0)) {
        return STRUCTURE_REVERSAL;
    }
    // Rango
    else {
        return STRUCTURE_RANGE;
    }
}

//+------------------------------------------------------------------+
//| Detectar patrón de acumulación                                  |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::IsAccumulationPattern(const MqlRates &rates[], int startBar, int count) {
   if(startBar + count > ArraySize(rates)) return false;
   
   // Características de acumulación:
   // 1. Rango estrecho
   // 2. Volumen en mínimos mayor que en máximos
   // 3. Soporte fuerte
   // 4. Springs (falsos rompimientos bajistas)
   
   double totalRange = 0;
   double volumeAtLows = 0;
   double volumeAtHighs = 0;
   int springs = 0;
   
   double lowest = rates[startBar].low;
   double highest = rates[startBar].high;
   
   for(int i = startBar; i < startBar + count; i++) {
      totalRange += rates[i].high - rates[i].low;
      lowest = MathMin(lowest, rates[i].low);
      highest = MathMax(highest, rates[i].high);
      
      // Volumen en zona baja vs alta
      double midPoint = (rates[i].high + rates[i].low) / 2;
      if(rates[i].close < midPoint) {
         volumeAtLows += (double)rates[i].tick_volume;
      } else {
         volumeAtHighs += (double)rates[i].tick_volume;
      }
      
      // Detectar springs
      if(i > startBar + 2) {
         if(rates[i].low < lowest && rates[i].close > rates[i].open &&
            rates[i].close > (rates[i].high + rates[i].low) / 2) {
            springs++;
         }
      }
   }
   
   double avgRange = totalRange / count;
   double overallRange = highest - lowest;
   
   // Criterios de acumulación
   bool narrowRange = avgRange < overallRange * 0.3;
   bool volumePattern = volumeAtLows > volumeAtHighs * 1.1;
   bool hasSpring = springs > 0;
   
   return narrowRange && (volumePattern || hasSpring);
}

//+------------------------------------------------------------------+
//| Detectar patrón de distribución                                 |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::IsDistributionPattern(const MqlRates &rates[], int startBar, int count) {
   if(startBar + count > ArraySize(rates)) return false;
   
   // Características de distribución:
   // 1. Rango amplio en máximos
   // 2. Volumen en máximos mayor que en mínimos
   // 3. Resistencia fuerte
   // 4. Upthrusts (falsos rompimientos alcistas)
   
   double totalRange = 0;
   double volumeAtLows = 0;
   double volumeAtHighs = 0;
   int upthrusts = 0;
   
   double lowest = rates[startBar].low;
   double highest = rates[startBar].high;
   
   for(int i = startBar; i < startBar + count; i++) {
      totalRange += rates[i].high - rates[i].low;
      lowest = MathMin(lowest, rates[i].low);
      highest = MathMax(highest, rates[i].high);
      
      // Volumen en zona alta vs baja
      double midPoint = (rates[i].high + rates[i].low) / 2;
      if(rates[i].close > midPoint) {
         volumeAtHighs += (double)rates[i].tick_volume;
      } else {
         volumeAtLows += (double)rates[i].tick_volume;
      }
      
      // Detectar upthrusts
      if(i > startBar + 2) {
         if(rates[i].high > highest && rates[i].close < rates[i].open &&
            rates[i].close < (rates[i].high + rates[i].low) / 2) {
            upthrusts++;
         }
      }
   }
   
   double avgRange = totalRange / count;
   double overallRange = highest - lowest;
   
   // Criterios de distribución
   bool wideRange = avgRange > overallRange * 0.25;
   bool volumePattern = volumeAtHighs > volumeAtLows * 1.1;
   bool hasUpthrust = upthrusts > 0;
   
   return wideRange && (volumePattern || hasUpthrust);
}

//+------------------------------------------------------------------+
//| Detectar patrón de Wyckoff                                      |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::DetectWyckoffPattern(const MqlRates &rates[], int count) {
   // Implementación simplificada de detección de patrones Wyckoff
   
   // Buscar fases características:
   // - PS (Preliminary Support) / PSY (Preliminary Supply)
   // - SC (Selling Climax) / BC (Buying Climax)
   // - AR (Automatic Rally) / AR (Automatic Reaction)
   // - ST (Secondary Test)
   // - Spring / Upthrust
   // - SOS (Sign of Strength) / SOW (Sign of Weakness)
   
   // Por simplicidad, detectamos patrones básicos
   
   // Detectar Selling Climax seguido de Automatic Rally (acumulación)
   for(int i = 10; i < count - 10; i++) {
      // Buscar volumen climático
      double avgVol = 0;
      for(int j = i + 1; j < i + 10; j++) {
         avgVol += (double)rates[j].tick_volume;
      }
      avgVol /= 9;
      
      if(rates[i].tick_volume > avgVol * 2.5) {
         // Posible climax
         bool isSellClimax = rates[i].close < rates[i].open && 
                            rates[i].low < rates[i+1].low;
         bool isBuyClimax = rates[i].close > rates[i].open && 
                           rates[i].high > rates[i+1].high;
         
         if(isSellClimax) {
            // Buscar rally automático
            bool rallyFound = false;
            for(int k = i - 5; k < i; k++) {
               if(rates[k].close > rates[k+1].close * 1.005) {
                  rallyFound = true;
                  break;
               }
            }
            
            if(rallyFound) {
               m_currentPhase = PHASE_ACCUMULATION;
               return true;
            }
         } else if(isBuyClimax) {
            // Buscar reacción automática
            bool reactionFound = false;
            for(int k = i - 5; k < i; k++) {
               if(rates[k].close < rates[k+1].close * 0.995) {
                  reactionFound = true;
                  break;
               }
            }
            
            if(reactionFound) {
               m_currentPhase = PHASE_DISTRIBUTION;
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detectar cacería de stops                                        |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::DetectStopHunt(const MqlRates &rates[], int bar) {
   if(bar >= ArraySize(rates) - 5 || bar < 5) return false;
   
   // Detectar spike seguido de reversión rápida
   double avgRange = 0;
   for(int i = bar - 5; i < bar; i++) {
      avgRange += rates[i].high - rates[i].low;
   }
   avgRange /= 5;
   
   // Spike bajista seguido de reversión
   if(rates[bar].low < rates[bar+1].low - avgRange && 
      rates[bar].close > (rates[bar].high + rates[bar].low) / 2) {
      // Verificar recuperación rápida
      if(bar > 0 && rates[bar-1].close > rates[bar].low + avgRange * 0.5) {
         return true;
      }
   }
   
   // Spike alcista seguido de reversión
   if(rates[bar].high > rates[bar+1].high + avgRange && 
      rates[bar].close < (rates[bar].high + rates[bar].low) / 2) {
      // Verificar caída rápida
      if(bar > 0 && rates[bar-1].close < rates[bar].high - avgRange * 0.5) {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calcular presión compradora/vendedora                           |
//+------------------------------------------------------------------+
double CInstitutionalPlanFinder::CalculateBuySellPressure(const MqlRates &rates[], int bar, double &buy, double &sell) {
    // Valores por defecto seguros
    buy = 50.0;
    sell = 50.0;
    
    // Validación de entrada
    if(bar < 0 || bar + 20 > ArraySize(rates)) {
        Print("CalculateBuySellPressure: Índice fuera de rango");
        return 0;
    }
    
    double buyVolume = 0;
    double sellVolume = 0;
    double totalVolume = 0;
    
    // NUEVO: Usar método más robusto para estimar presión
    for(int i = bar; i < bar + 20 && i < ArraySize(rates); i++) {
        double vol = (double)rates[i].tick_volume;
        if(vol <= 0) continue; // Ignorar barras sin volumen
        
        totalVolume += vol;
        
        // CORRECCIÓN: Método mejorado para estimar volumen comprador/vendedor
        double range = rates[i].high - rates[i].low;
        double body = MathAbs(rates[i].close - rates[i].open);
        
        if(range > 0) {
            // Método 1: Posición del cierre en el rango
            double closePos = (rates[i].close - rates[i].low) / range;
            
            // Método 2: Dirección de la vela
            double direction = (rates[i].close > rates[i].open) ? 0.6 : 0.4;
            
            // Método 3: Tamaño del cuerpo vs rango
            double bodyRatio = (range > 0) ? body / range : 0.5;
            
            // Combinar métodos con pesos
            double buyRatio = (closePos * 0.5) + (direction * 0.3) + (bodyRatio * 0.2);
            buyRatio = MathMax(0.1, MathMin(0.9, buyRatio)); // Limitar entre 10% y 90%
            
            buyVolume += vol * buyRatio;
            sellVolume += vol * (1.0 - buyRatio);
        } else {
            // Barra sin rango (doji perfecto)
            // Usar análisis de contexto
            if(i > 0 && i < ArraySize(rates) - 1) {
                // Comparar con barra anterior y siguiente
                double prevClose = rates[i-1].close;
                double nextOpen = (i+1 < ArraySize(rates)) ? rates[i+1].open : rates[i].close;
                
                if(rates[i].close > prevClose && rates[i].close < nextOpen) {
                    buyVolume += vol * 0.55;
                    sellVolume += vol * 0.45;
                } else if(rates[i].close < prevClose && rates[i].close > nextOpen) {
                    buyVolume += vol * 0.45;
                    sellVolume += vol * 0.55;
                } else {
                    buyVolume += vol * 0.5;
                    sellVolume += vol * 0.5;
                }
            } else {
                // Distribución neutral
                buyVolume += vol * 0.5;
                sellVolume += vol * 0.5;
            }
        }
    }
    
    // Calcular porcentajes con verificación
    if(totalVolume > 0) {
        buy = (buyVolume / totalVolume) * 100.0;
        sell = (sellVolume / totalVolume) * 100.0;
        
        // Normalizar para que sumen 100%
        double total = buy + sell;
        if(total > 0 && MathAbs(total - 100.0) > 0.01) {
            buy = (buy / total) * 100.0;
            sell = (sell / total) * 100.0;
        }
    }
    
    // Retornar delta
    return buy - sell;
}
//+------------------------------------------------------------------+
//| Dibujar zona institucional                                      |
//+------------------------------------------------------------------+
void CInstitutionalPlanFinder::DrawInstitutionalZone(const InstitutionalFootprint &footprint) {
   if(!m_showVisual) return;
   
   string name = m_prefix + "ZONE_" + TimeToString(footprint.time);
   
   // Calcular zona basada en la fase
   double zoneHigh = footprint.priceLevel;
   double zoneLow = footprint.priceLevel;
   double zoneSize = footprint.priceLevel * 0.002; // 0.2%
   
   switch(footprint.phase) {
      case PHASE_ACCUMULATION:
         zoneLow -= zoneSize;
         break;
      case PHASE_DISTRIBUTION:
         zoneHigh += zoneSize;
         break;
      case PHASE_MARKUP:
         zoneLow = footprint.priceLevel - zoneSize * 0.5;
         zoneHigh = footprint.priceLevel + zoneSize * 1.5;
         break;
      case PHASE_MARKDOWN:
         zoneLow = footprint.priceLevel - zoneSize * 1.5;
         zoneHigh = footprint.priceLevel + zoneSize * 0.5;
         break;
   }
   
   datetime endTime = footprint.time + PeriodSeconds(m_timeframe) * 50;
   
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, footprint.time, zoneHigh, endTime, zoneLow);
   ObjectSetInteger(0, name, OBJPROP_COLOR, GetPhaseColor(footprint.phase, footprint.confidence));
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   // Etiqueta
   string labelName = name + "_LABEL";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, footprint.time, zoneHigh);
   ObjectSetString(0, labelName, OBJPROP_TEXT, EnumToString(footprint.phase));
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Dibujar perfil de volumen                                       |
//+------------------------------------------------------------------+
void CInstitutionalPlanFinder::DrawVolumeProfile() {
   if(!m_showVisual || m_profileNodeCount == 0) return;
   
   // Limpiar perfil anterior
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, m_prefix + "VP_") == 0) {
         ObjectDelete(0, name);
      }
   }
   
   // Encontrar volumen máximo para escalar
   double maxVolume = 0;
   for(int i = 0; i < m_profileNodeCount; i++) {
      maxVolume = MathMax(maxVolume, m_volumeProfile[i].volume);
   }
   
   if(maxVolume == 0) return;
   
   // Dibujar barras de volumen
   datetime currentTime = TimeCurrent();
   int barsToShow = 50;
   
   for(int i = 0; i < m_profileNodeCount; i++) {
      if(m_volumeProfile[i].volume == 0) continue;
      
      string name = m_prefix + "VP_" + IntegerToString(i);
      
      double barLength = (m_volumeProfile[i].volume / maxVolume) * barsToShow;
      datetime startTime = currentTime - (int)(barLength * PeriodSeconds(m_timeframe));
      
      ObjectCreate(0, name, OBJ_TREND, 0, startTime, m_volumeProfile[i].price, 
                   currentTime, m_volumeProfile[i].price);
      
      // Color basado en tipo de nodo
      color barColor = clrGray;
      int width = 1;
      
      if(m_volumeProfile[i].isPOC) {
         barColor = clrYellow;
         width = 3;
      } else if(m_volumeProfile[i].isHVN) {
         barColor = clrLime;
         width = 2;
      } else if(m_volumeProfile[i].isLVN) {
         barColor = clrRed;
         width = 1;
      }
      
      ObjectSetInteger(0, name, OBJPROP_COLOR, barColor);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_RAY, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Obtener color según fase y confianza                            |
//+------------------------------------------------------------------+
color CInstitutionalPlanFinder::GetPhaseColor(ENUM_INSTITUTIONAL_PHASE phase, double confidence) {
   // Usar colores sólidos - MQL5 maneja transparencia de manera diferente
   // La transparencia se puede ajustar con OBJPROP_COLOR en el objeto
   
   switch(phase) {
      case PHASE_ACCUMULATION:
         return clrDodgerBlue;
         
      case PHASE_MARKUP:
         return clrLime;
         
      case PHASE_DISTRIBUTION:
         return clrOrange;
         
      case PHASE_MARKDOWN:
         return clrRed;
         
      default:
         return clrGray;
   }
}

//+------------------------------------------------------------------+
//| Actualizar visualización                                        |
//+------------------------------------------------------------------+
void CInstitutionalPlanFinder::UpdateVisual() {
   if(!m_showVisual) return;
   
   // Actualizar zonas existentes
   if(m_currentFootprint.time > 0 && m_currentFootprint.confirmed) {
      DrawInstitutionalZone(m_currentFootprint);
   }
}

//+------------------------------------------------------------------+
//| Obtener perfil de volumen                                       |
//+------------------------------------------------------------------+
bool CInstitutionalPlanFinder::GetVolumeProfile(VolumeNode &nodes[], int &nodeCount) {
   nodeCount = m_profileNodeCount;
   if(nodeCount <= 0) return false;
   
   ArrayResize(nodes, nodeCount);
   for(int i = 0; i < nodeCount; i++) {
      nodes[i] = m_volumeProfile[i];
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Obtener punto de control (POC)                                  |
//+------------------------------------------------------------------+
double CInstitutionalPlanFinder::GetPointOfControl() {
   for(int i = 0; i < m_profileNodeCount; i++) {
      if(m_volumeProfile[i].isPOC) {
         return m_volumeProfile[i].price;
      }
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Imprimir análisis institucional                                 |
//+------------------------------------------------------------------+
void CInstitutionalPlanFinder::PrintInstitutionalAnalysis() {
   Print("=== ANÁLISIS INSTITUCIONAL ===");
   Print("Fase actual: ", EnumToString(m_currentPhase));
   
   if(m_currentFootprint.time > 0) {
      Print("Huella institucional:");
      Print("- Tiempo: ", TimeToString(m_currentFootprint.time));
      Print("- Confirmada: ", m_currentFootprint.confirmed ? "SÍ" : "NO");
      Print("- Smart Money Index: ", DoubleToString(m_currentFootprint.smartMoneyIndex, 1));
      Print("- Presión compradora: ", DoubleToString(m_currentFootprint.buyPressure, 1), "%");
      Print("- Presión vendedora: ", DoubleToString(m_currentFootprint.sellPressure, 1), "%");
      Print("- Estructura: ", EnumToString(m_currentFootprint.structure));
      Print("- Anomalía volumen: ", m_currentFootprint.hasVolumeAnomaly ? "SÍ" : "NO");
      Print("- Duración: ", m_currentFootprint.duration, " barras");
      Print("- Confianza: ", DoubleToString(m_currentFootprint.confidence, 1), "%");
   }
   
   double poc = GetPointOfControl();
   if(poc > 0) {
      Print("Point of Control: ", DoubleToString(poc, _Digits));
   }
   
   Print("=============================");
}

#endif // __INSTITUTIONALPLANFINDER_FIXED_MQH__
