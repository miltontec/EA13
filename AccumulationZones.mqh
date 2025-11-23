//+------------------------------------------------------------------+
//|                                        AccumulationZones.mqh |
//|                        Copyright 2025, Trading Strategy Developer |
//|                                             https://www.domain.com |
//+------------------------------------------------------------------+
#ifndef ACCUMULATION_ZONES_MQH
#define ACCUMULATION_ZONES_MQH

#property copyright "Copyright 2025, Trading Strategy Developer"
#property link      "https://www.domain.com"


// Incluir dependencias
#include <SupportResistance.mqh>
#ifndef SR_LEVEL_STRUCT_DEFINED
#define SR_LEVEL_STRUCT_DEFINED

#endif // SR_LEVEL_STRUCT_DEFINED


#ifndef TREND_DIRECTION_ENUM_DEFINED
#define TREND_DIRECTION_ENUM_DEFINED
enum ENUM_TREND_DIRECTION {
   TREND_NONE = 0,
   TREND_UP,
   TREND_DOWN,
   MARKET_BREAKOUT
};
#endif // TREND_DIRECTION_ENUM_DEFINED

// Definición de la estructura para zonas de acumulación
struct AccumulationZone {
   double          price;           // Precio central de la zona
   ENUM_SR_TYPE    levelType;       // Tipo de nivel (soporte o resistencia)
   datetime        startTime;       // Inicio de la acumulación
   datetime        endTime;         // Fin de la acumulación (si completada)
   double          highPrice;       // Precio máximo de la zona
   double          lowPrice;        // Precio mínimo de la zona
   int             barCount;        // Número de barras en la acumulación
   int             touches;         // Número de toques
   double          strength;        // Fortaleza de la señal (0.0-10.0)
   bool            active;          // Si la zona está activa
   bool            confirmed;       // Si la acumulación está confirmada
   int             id;              // Identificador único
   int             srLevelId;       // ID del nivel S/R relacionado
   double          volumeAvg;       // Volumen promedio durante acumulación
   double          volatilityRatio; // Ratio de volatilidad (acumulación vs normal)
};

// Clase principal para la gestión de zonas de acumulación
class CAccumulationZones {
private:
   // Configuración
   ENUM_TIMEFRAMES m_timeframe;      // Timeframe para análisis
   bool            m_showVisual;     // Mostrar elementos visuales
   int             m_minBars;        // Mínimo de barras para confirmar acumulación
   int             m_maxBars;        // Máximo de barras para considerar acumulación
   double          m_maxRangePercent;// Rango máximo como % del precio para acumulación
   int             m_zoneCount;      // Contador para IDs de zonas
   
   // Control de visualización
   datetime        m_lastVisualUpdate;   // Última actualización visual
   bool            m_visualNeedsUpdate;  // Bandera para indicar necesidad de actualización
   
   // Datos internos
   AccumulationZone m_zones[];       // Array de zonas identificadas
   int             m_zonesCount;     // Cantidad de zonas activas
   bool            m_initialized;    // Estado de inicialización
   string          m_prefix;         // Prefijo para objetos gráficos
   
   // Buffers para cálculos
   double          m_atr[];          // Buffer para ATR
   int             m_atrHandle;      // Handle del indicador ATR
   
   // Métodos privados
   bool            IsAccumulationPattern(int startBar, int &endBar, double &highPrice, double &lowPrice);
   double          CalculateVolumeProfile(int startBar, int endBar);
   double          CalculateVolatilityRatio(int startBar, int endBar);
   bool            DetectCompression(int startBar, int barCount);
   bool            AnalyzeVolumePattern(int startBar, int barCount);
   bool            IsNearExistingLevel(double price, ENUM_SR_TYPE type);
   bool            MergeSimilarLevels();
   void            SortLevelsByStrength();
   double          CalculateLevelStrength(int index, int touches, datetime firstTouch);
   bool            CreateZoneObjects(AccumulationZone &zone);
   void            IdentifyLevels();
   void            ValidateLevelsWithVolume();
   color           GetColorByStrength(double strength, ENUM_SR_TYPE type);
   ENUM_LINE_STYLE GetLineStyleByStrength(double strength);
   int             GetLineWidthByStrength(double strength);
   double          GetCurrentATR(int period = 14);
   void            ApplyTemporalDecay();
   void            UpdateValidationMetrics();
   void            IdentifyClusteredZones();
   
   double          ScoreAccumulationZone(int zoneIndex);
   double          GetAverageVolume();
public:

// NUEVOS MÉTODOS PARA VOTACIÓN
    // Retorna dirección y confianza
    ENUM_TREND_DIRECTION GetVoteDirection(double &confidence);
// NUEVOS MÉTODOS PARA VOTACIÓN
    ENUM_TREND_DIRECTION GetZoneDirection(double currentPrice);
    
    double GetZoneConfidence();
                   CAccumulationZones(); // Constructor
                  ~CAccumulationZones(); // Destructor
   
   // Métodos públicos
   bool            Init(ENUM_TIMEFRAMES timeframe, bool showVisual);
   int             FindAccumulations(SRLevel &srLevels[], int srCount, AccumulationZone &zones[]);
   bool            IsInAccumulationZone(double price, AccumulationZone &zone);
   void            UpdateVisual();
   void            ClearZones();
   bool            GetZoneById(int id, AccumulationZone &zone);
   
};



//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAccumulationZones::CAccumulationZones() {
   m_timeframe = PERIOD_CURRENT;
   m_showVisual = true;
   m_minBars = 2;
   m_maxBars = 20;
   m_maxRangePercent = 0.5; // Aumentado para mayor sensibilidad
   m_zoneCount = 0;
   m_zonesCount = 0;
   m_initialized = false;
   m_prefix = "ACCUM_";
   m_atrHandle = INVALID_HANDLE;
   m_lastVisualUpdate = 0;
   m_visualNeedsUpdate = true;
   
   ArrayResize(m_zones, 1);
   ArrayResize(m_atr, 1);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAccumulationZones::~CAccumulationZones() {
   // Eliminar objetos gráficos
   if(m_showVisual) {
      ObjectsDeleteAll(0, m_prefix);
   }
   
   // Liberar handle del indicador
   if(m_atrHandle != INVALID_HANDLE) {
      IndicatorRelease(m_atrHandle);
      m_atrHandle = INVALID_HANDLE;
   }
   
   // Liberar arrays
   ArrayFree(m_zones);
   ArrayFree(m_atr);
}

//+------------------------------------------------------------------+
//| Inicialización del componente                                    |
//+------------------------------------------------------------------+
bool CAccumulationZones::Init(ENUM_TIMEFRAMES timeframe, bool showVisual) {
   m_timeframe = timeframe;
   m_showVisual = showVisual;
   
   // Inicializar indicador ATR para medir volatilidad
   m_atrHandle = iATR(Symbol(), m_timeframe, 14);
   if(m_atrHandle==INVALID_HANDLE) {
      m_atrHandle = iATR(Symbol(), PERIOD_CURRENT, 14);
   }
   if(m_atrHandle == INVALID_HANDLE) {
      Print("Error: No se pudo crear handle ATR");
      return false;
   }
   
   // Ajustar el rango máximo basado en ATR
   ArraySetAsSeries(m_atr, true);
   if(CopyBuffer(m_atrHandle, 0, 0, 1, m_atr) > 0) {
      double atr = m_atr[0];
      
      if(atr > 0) {
         // Calcular el porcentaje basado en ATR y precio actual
         double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         if(currentPrice > 0) {
            m_maxRangePercent = (atr / currentPrice) * 100.0 * 0.75; // 75% del ATR
         }
      }
   }
   
   m_initialized = true;
   Print("AccumulationZones inicializado - Rango máximo: ", DoubleToString(m_maxRangePercent, 2), "%");
   return true;
}

//+------------------------------------------------------------------+
//| Obtiene el ATR actual para cálculos de volatilidad               |
//+------------------------------------------------------------------+
double CAccumulationZones::GetCurrentATR(int period = 14) {
   if(m_atrHandle == INVALID_HANDLE) return 0.0;
   
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   
   if(CopyBuffer(m_atrHandle, 0, 0, 1, atrBuffer) > 0) {
      return atrBuffer[0];
   }
   
   // Valor por defecto si falla
   return 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Busca zonas de acumulación cerca de niveles S/R                  |
//+------------------------------------------------------------------+
int CAccumulationZones::FindAccumulations(SRLevel &srLevels[], int srCount, AccumulationZone &zones[]) {
   
    // Debounce: procesa solo en nueva barra o si el precio se movió >=5 ticks
    static datetime __acc_last_bar = 0;
    static double   __acc_last_probe = 0.0;
    datetime __acc_cur_bar = iTime(_Symbol, _Period, 0);
    double   __acc_price   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double   __pt          = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if(__acc_cur_bar == __acc_last_bar && MathAbs(__acc_price - __acc_last_probe) < 5.0*__pt){
        return m_zonesCount; // sin cambios
    }
    __acc_last_bar = __acc_cur_bar;
    __acc_last_probe = __acc_price;
if(!m_initialized || srCount <= 0) return 0;
   
   // Limpiar zonas obsoletas
   int i = 0;
   while(i < m_zonesCount) {
      if(!m_zones[i].active || 
         (m_zones[i].confirmed && m_zones[i].endTime < TimeCurrent() - 24 * 3600)) {
         // Eliminar zona
         for(int j = i; j < m_zonesCount - 1; j++) {
            m_zones[j] = m_zones[j + 1];
         }
         m_zonesCount--;
         continue;
      }
      i++;
   }
   
   // Obtener datos de precio
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), m_timeframe, 0, 200, rates);
   
   if(copied <= 0) {
      Print("Error: No se pudieron copiar datos de precio");
      return 0;
   }
   
   // Actualizar ATR
   ArraySetAsSeries(m_atr, true);
   if(CopyBuffer(m_atrHandle, 0, 0, 200, m_atr) <= 0) {
      Print("Error: No se pudo copiar buffer ATR");
      return 0;
   }
   
   // Para cada nivel S/R, buscar patrones de acumulación cercanos
   for(i = 0; i < srCount; i++) {
      double levelPrice = srLevels[i].price;  // CORREGIDO: era centerPrice
      ENUM_SR_TYPE levelType = srLevels[i].type;
      
      // Buscar si el precio ha tocado este nivel recientemente
      for(int j = 0; j < MathMin(100, copied); j++) {
         // Verificación de seguridad
         if(j >= ArraySize(rates) || j >= ArraySize(m_atr)) {
            continue;
         }
         
         double atrMargin = m_atr[j] * 1.2; // Margen más amplio
         bool levelTouched = false;
         
         if(levelType == SR_SUPPORT) {
            // El precio bajo tocó el soporte o se acercó lo suficiente
            if(rates[j].low <= levelPrice + atrMargin && rates[j].low >= levelPrice - atrMargin) {
               levelTouched = true;
            }
         } else { // SR_RESISTANCE
            // El precio alto tocó la resistencia o se acercó lo suficiente
            if(rates[j].high >= levelPrice - atrMargin && rates[j].high <= levelPrice + atrMargin) {
               levelTouched = true;
            }
         }
         
         if(levelTouched) {
            // Verificar si hay un patrón de acumulación a partir de este punto
            int endBar = 0;
            double highPrice = 0.0, lowPrice = 0.0;
            
            if(IsAccumulationPattern(j, endBar, highPrice, lowPrice)) {
               // Verificar si esta zona ya existe
               bool zoneExists = false;
               for(int k = 0; k < m_zonesCount; k++) {
                  if(MathAbs(m_zones[k].price - levelPrice) < m_atr[0] * 0.7 && 
                     m_zones[k].levelType == levelType) {
                     zoneExists = true;
                     
                     // Actualizar zona existente si es necesario
                     if(!m_zones[k].confirmed) {
                        m_zones[k].endTime = rates[endBar].time;
                        m_zones[k].barCount = j - endBar + 1;
                        m_zones[k].highPrice = highPrice;
                        m_zones[k].lowPrice = lowPrice;
                        m_zones[k].confirmed = true;
                        m_zones[k].strength = CalculateLevelStrength(k, 0, rates[j].time);
                        
                        // Actualizar visualización
                        if(m_showVisual) {
                           CreateZoneObjects(m_zones[k]);
                        }
                     }
                     break;
                  }
               }
               
               if(!zoneExists) {
                  // Crear nueva zona de acumulación
                  m_zonesCount++;
                  ArrayResize(m_zones, m_zonesCount);
                  
                  m_zones[m_zonesCount - 1].price = levelPrice;
                  m_zones[m_zonesCount - 1].levelType = levelType;
                  m_zones[m_zonesCount - 1].startTime = rates[j].time;
                  m_zones[m_zonesCount - 1].endTime = rates[endBar].time;
                  m_zones[m_zonesCount - 1].highPrice = highPrice;
                  m_zones[m_zonesCount - 1].lowPrice = lowPrice;
                  m_zones[m_zonesCount - 1].barCount = j - endBar + 1;
                  m_zones[m_zonesCount - 1].touches = j - endBar + 1;
                  m_zones[m_zonesCount - 1].active = true;
                  m_zones[m_zonesCount - 1].confirmed = true;
                  m_zones[m_zonesCount - 1].id = m_zoneCount++;
                  m_zones[m_zonesCount - 1].srLevelId = srLevels[i].id;
                  m_zones[m_zonesCount - 1].volumeAvg = CalculateVolumeProfile(endBar, j);
                  m_zones[m_zonesCount - 1].volatilityRatio = CalculateVolatilityRatio(endBar, j);
                  m_zones[m_zonesCount - 1].strength = CalculateLevelStrength(m_zonesCount - 1, j - endBar + 1, rates[j].time);
                  
                  // Crear objetos visuales
                  if(m_showVisual) {
                     CreateZoneObjects(m_zones[m_zonesCount - 1]);
                  }
                  
                  Print("Nueva zona de acumulación #", m_zones[m_zonesCount - 1].id, 
                        " en nivel ", (levelType == SR_SUPPORT ? "SOPORTE" : "RESISTENCIA"));
               }
               
               // No seguir buscando en barras anteriores para este nivel
               break;
            }
         }
      }
   }
   
   // Actualizar visualización
   if(m_showVisual) {
      UpdateVisual();
   }
   
   // Copiar resultados al array de salida
   ArrayResize(zones, m_zonesCount);
   for(i = 0; i < m_zonesCount; i++) {
      zones[i] = m_zones[i];
   }
   
   return m_zonesCount;
}

//+------------------------------------------------------------------+
//| Verifica si un precio está dentro de una zona de acumulación     |
//+------------------------------------------------------------------+
bool CAccumulationZones::IsInAccumulationZone(double price, AccumulationZone &zone) {
   if(!m_initialized || m_zonesCount <= 0) return false;
   
   for(int i = 0; i < m_zonesCount; i++) {
      if(m_zones[i].active && m_zones[i].confirmed) {
         double zoneMin = MathMin(m_zones[i].price, m_zones[i].lowPrice);
         double zoneMax = MathMax(m_zones[i].price, m_zones[i].highPrice);
         
         if(price >= zoneMin && price <= zoneMax) {
            zone = m_zones[i];
            return true;
         }
      }
   }
   
   return false;
}

// Sistema de puntuación para zonas
double CAccumulationZones::ScoreAccumulationZone(int zoneIndex) {
    if(zoneIndex >= m_zonesCount) return 0.0;
    
    AccumulationZone zone = m_zones[zoneIndex];
    double score = 0.0;
    
    // Factor 1: Fuerza base
    score += zone.strength * 10.0;
    
    // Factor 2: Número de toques
    score += zone.touches * 5.0;
    
    // Factor 3: Volatilidad en la zona
    if(zone.volatilityRatio < 0.5) score += 20.0; // Baja volatilidad = mejor
    
    // Factor 4: Volumen
    if(zone.volumeAvg > GetAverageVolume() * 1.5) score += 15.0;
    
    return MathMin(100.0, score);
}
//+------------------------------------------------------------------+
//| Actualiza los elementos visuales en el gráfico                   |
//+------------------------------------------------------------------+
void CAccumulationZones::UpdateVisual() {
   if(!m_showVisual || !m_initialized) return;
   
   // Reducir frecuencia de actualización (máximo cada 2 segundos)
   datetime currentTime = TimeCurrent();
   if(currentTime - m_lastVisualUpdate < 2 && !m_visualNeedsUpdate) return;
   
   m_lastVisualUpdate = currentTime;
   m_visualNeedsUpdate = false;
   
   // Eliminar objetos existentes
   ObjectsDeleteAll(0, m_prefix);
   
   // Crear objetos para cada zona
   for(int i = 0; i < m_zonesCount; i++) {
      if(m_zones[i].active) {
         CreateZoneObjects(m_zones[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Limpia todas las zonas identificadas                             |
//+------------------------------------------------------------------+
void CAccumulationZones::ClearZones() {
   ArrayResize(m_zones, 1);
   m_zonesCount = 0;
   
   if(m_showVisual) {
      ObjectsDeleteAll(0, m_prefix);
   }
}

//+------------------------------------------------------------------+
//| Obtiene una zona por su ID                                       |
//+------------------------------------------------------------------+
bool CAccumulationZones::GetZoneById(int id, AccumulationZone &zone) {
   for(int i = 0; i < m_zonesCount; i++) {
      if(m_zones[i].id == id) {
         zone = m_zones[i];
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Verifica si hay un patrón de acumulación desde una barra         |
//+------------------------------------------------------------------+
bool CAccumulationZones::IsAccumulationPattern(int startBar, int &endBar, double &highPrice, double &lowPrice) {
    // Obtener datos
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // CORRECCIÓN: Calcular datos necesarios correctamente
    int barsNeeded = startBar + m_maxBars + 1;
    int copied = CopyRates(Symbol(), m_timeframe, 0, barsNeeded, rates);
    
    if(copied < barsNeeded || copied <= startBar) {
        Print("IsAccumulationPattern: Datos insuficientes. Necesarios: ", barsNeeded, ", Copiados: ", copied);
        return false;
    }
    
    // CORRECCIÓN: Verificar ATR con el mismo tamaño
    ArraySetAsSeries(m_atr, true);
    if(CopyBuffer(m_atrHandle, 0, 0, barsNeeded, m_atr) < barsNeeded) {
        Print("IsAccumulationPattern: Buffer ATR insuficiente");
        return false;
    }
    
    // Variables de control
    int barCount = 0;
    double accHigh = rates[startBar].high;
    double accLow = rates[startBar].low;
    
    highPrice = accHigh;
    lowPrice = accLow;
    
    // Rango máximo permitido
    double maxRange = m_atr[startBar] * 1.5;
    
    // CORRECCIÓN: Límite seguro para el loop
    int maxIterations = MathMin(m_maxBars, copied - startBar - 1);
    
    for(int i = startBar + 1; i < startBar + maxIterations; i++) {
        // NUEVA VERIFICACIÓN: Doble check de límites
        if(i >= ArraySize(rates) || i >= ArraySize(m_atr)) {
            Print("IsAccumulationPattern: Índice fuera de rango en loop: ", i);
            break;
        }
        
        // Verificar si el rango es demasiado grande
        double currentRange = rates[i].high - rates[i].low;
        if(i > startBar + 2 && currentRange > maxRange * 2.0) {
            break;
        }
        
        // Actualizar rango
        accHigh = MathMax(accHigh, rates[i].high);
        accLow = MathMin(accLow, rates[i].low);
        
        // Verificar rango total
        if((accHigh - accLow) > maxRange * 3.0) {
            break;
        }
        
        barCount++;
        highPrice = accHigh;
        lowPrice = accLow;
        
        // Verificar condiciones de acumulación
        if(barCount >= m_minBars) {
            if(DetectCompression(startBar, barCount)) {
                if(AnalyzeVolumePattern(startBar, barCount)) {
                    endBar = i;
                    return true;
                }
            }
        }
    }
    
    // Verificar si tenemos suficientes barras con compresión
    if(barCount >= m_minBars && DetectCompression(startBar, barCount)) {
        endBar = startBar + barCount;
        return true;
    }
    
    return false;
}
//+------------------------------------------------------------------+
//| Calcula el perfil de volumen de una zona                         |
//+------------------------------------------------------------------+
double CAccumulationZones::CalculateVolumeProfile(int startBar, int endBar) {
   // Obtener datos
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), m_timeframe, 0, MathMax(startBar, endBar) + 1, rates);
   
   if(copied <= 0) return 0.0;
   
   double volumeSum = 0.0;
   int count = 0;
   
   int minBar = MathMin(startBar, endBar);
   int maxBar = MathMax(startBar, endBar);
   
   for(int i = minBar; i <= maxBar; i++) {
      if(i < copied) {
         volumeSum += (double)rates[i].tick_volume;
         count++;
      }
   }
   
   return (count > 0) ? volumeSum / count : 0;
}

///+------------------------------------------------------------------+
//| Calcula la relación de volatilidad                              |
//+------------------------------------------------------------------+
double CAccumulationZones::CalculateVolatilityRatio(int startBar, int endBar) {
   // CORRECCIÓN: Validar parámetros de entrada
   if(startBar < 0 || endBar < 0 || startBar > endBar) {
      Print("CalculateVolatilityRatio: Parámetros inválidos");
      return 1.0;
   }
   
   // Asegurar que tenemos suficientes datos en el buffer ATR
   int maxBar = MathMax(startBar, endBar);
   ArraySetAsSeries(m_atr, true);
   
   if(CopyBuffer(m_atrHandle, 0, 0, maxBar + 1, m_atr) <= maxBar) {
      Print("CalculateVolatilityRatio: Buffer ATR insuficiente");
      return 1.0;
   }
   
   // Verificar límites de arrays
   if(maxBar >= ArraySize(m_atr)) {
      Print("CalculateVolatilityRatio: Índices fuera del rango del array ATR");
      return 1.0;
   }
   
   // Obtener ATR para el período de acumulación
   double accumVolatility = 0.0;
   int count = 0;
   
   int minBar = MathMin(startBar, endBar);
   maxBar = MathMax(startBar, endBar);
   
   for(int i = minBar; i <= maxBar; i++) {
      if(i < ArraySize(m_atr)) {
         accumVolatility += m_atr[i];
         count++;
      }
   }
   
   // Volatilidad promedio durante acumulación
   double avgAccumVolatility = (count > 0) ? accumVolatility / count : 0;
   
   // Volatilidad promedio general
   double avgATR = 0.0;
   int generalCount = MathMin(14, ArraySize(m_atr));
   
   for(int i = 0; i < generalCount; i++) {
      avgATR += m_atr[i];
   }
   
   if(generalCount > 0) {
      avgATR /= generalCount;
   }
   
   // Ratio: < 1.0 significa menor volatilidad en acumulación
   return (avgATR > 0) ? avgAccumVolatility / avgATR : 1.0;
}

//+------------------------------------------------------------------+
//| Crea objetos gráficos para una zona                              |
//+------------------------------------------------------------------+
bool CAccumulationZones::CreateZoneObjects(AccumulationZone &zone) {
   if(!m_showVisual) return true;
   
   string namePrefix = m_prefix + IntegerToString(zone.id) + "_";
   color zoneColor = (zone.levelType == SR_SUPPORT) ? clrDodgerBlue : clrCrimson;
   
   // Crear rectángulo de zona
   string zoneName = namePrefix + "Zone";
   if(ObjectCreate(0, zoneName, OBJ_RECTANGLE, 0, zone.startTime, zone.highPrice, 
                  zone.endTime, zone.lowPrice)) {
      ObjectSetInteger(0, zoneName, OBJPROP_COLOR, zoneColor);
      ObjectSetInteger(0, zoneName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, zoneName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, zoneName, OBJPROP_FILL, true);
      ObjectSetInteger(0, zoneName, OBJPROP_BACK, true);
      ObjectSetInteger(0, zoneName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, zoneName, OBJPROP_SELECTED, false);
      
      // Tooltip
      ObjectSetString(0, zoneName, OBJPROP_TOOLTIP, 
                     (zone.levelType == SR_SUPPORT ? "Acumulación (Soporte)" : "Acumulación (Resistencia)") + 
                     " #" + IntegerToString(zone.id) + 
                     " (" + DoubleToString(zone.strength, 1) + ")");
      
      // Crear texto con número 1 dentro del rectángulo
      string textName = namePrefix + "Text";
      datetime middleTime = (zone.startTime + zone.endTime) / 2;
      double middlePrice = (zone.highPrice + zone.lowPrice) / 2;
      
      if(ObjectCreate(0, textName, OBJ_TEXT, 0, middleTime, middlePrice)) {
         ObjectSetString(0, textName, OBJPROP_TEXT, "1");
         ObjectSetInteger(0, textName, OBJPROP_COLOR, clrBlack);
         ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 12);
         ObjectSetString(0, textName, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
         ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, textName, OBJPROP_SELECTED, false);
      }
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detecta si hay compresión de precios (menor volatilidad)         |
//+------------------------------------------------------------------+
bool CAccumulationZones::DetectCompression(int startBar, int barCount) {
   // Obtener datos
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), m_timeframe, 0, startBar + barCount + 10, rates);
   
   if(copied <= startBar + barCount) return false;
   
   // Calcular volatilidad antes de la potencial acumulación
   double prevVolatility = 0.0;
   int prevBars = 0;
   
   for(int i = startBar + barCount + 1; i <= startBar + barCount + 5; i++) {
      if(i < ArraySize(rates)) {
         prevVolatility += MathAbs(rates[i].high - rates[i].low);
         prevBars++;
      }
   }
   
   if(prevBars > 0) prevVolatility /= prevBars;
   
   // Calcular volatilidad durante la acumulación
   double accumVolatility = 0.0;
   int accumBars = 0;
   
   for(int i = startBar; i <= startBar + barCount; i++) {
      if(i >= 0 && i < ArraySize(rates)) {
         accumVolatility += MathAbs(rates[i].high - rates[i].low);
         accumBars++;
      }
   }
   
   if(accumBars > 0) accumVolatility /= accumBars;
   
   // Comprobar si hay compresión (volatilidad reducida)
   return accumVolatility < prevVolatility * 0.85; // 15% de reducción mínima
}

//+------------------------------------------------------------------+
//| Analiza el patrón de volumen durante la acumulación              |
//+------------------------------------------------------------------+
bool CAccumulationZones::AnalyzeVolumePattern(int startBar, int barCount) {
   // Obtener datos
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), m_timeframe, 0, startBar + barCount + 10, rates);
   
   if(copied <= startBar + barCount) return false;
   
   // Calcular volumen promedio antes de la acumulación
   double prevVolume = 0.0;
   int prevBars = 0;
   
   for(int i = startBar + barCount + 1; i <= startBar + barCount + 5; i++) {
      if(i < ArraySize(rates)) {
         prevVolume += (double)rates[i].tick_volume;
         prevBars++;
      }
   }
   
   if(prevBars > 0) prevVolume /= prevBars;
   
   // Calcular volumen durante la acumulación
   double accumVolume = 0.0;
   int highVolumeCount = 0;
   int accumBars = 0;
   
   for(int i = startBar; i <= startBar + barCount; i++) {
      if(i >= 0 && i < ArraySize(rates)) {
         accumVolume += (double)rates[i].tick_volume;
         accumBars++;
         
         // Contar barras con volumen alto
         if(rates[i].tick_volume > prevVolume * 1.2) {
            highVolumeCount++;
         }
      }
   }
   
   if(accumBars > 0) accumVolume /= accumBars;
   
   // Patrón 1: Volumen promedio mayor durante acumulación
   bool pattern1 = accumVolume > prevVolume * 1.03; // Solo 3% más
   
   // Patrón 2: Al menos una barra con volumen significativamente mayor
   bool pattern2 = highVolumeCount >= 1;
   
   // Patrón 3: Volumen decreciente hacia el final de la acumulación
   bool pattern3 = true;
   if(barCount >= 4) {
      double startVolume = 0.0, endVolume = 0.0;
      int halfCount = barCount / 2;
      int startCount = 0, endCount = 0;
      
      for(int i = startBar; i < startBar + halfCount; i++) {
         if(i >= 0 && i < ArraySize(rates)) {
            startVolume += (double)rates[i].tick_volume;
            startCount++;
         }
      }
      
      for(int i = startBar + halfCount; i <= startBar + barCount; i++) {
         if(i >= 0 && i < ArraySize(rates)) {
            endVolume += (double)rates[i].tick_volume;
            endCount++;
         }
      }
      
      if(startCount > 0) startVolume /= startCount;
      if(endCount > 0) endVolume /= endCount;
      
      pattern3 = endVolume < startVolume * 0.95;
   }
   
   // Requerir al menos uno de los tres patrones
   return pattern1 || pattern2 || pattern3;
}

//+------------------------------------------------------------------+
//| Calcula la fortaleza de una zona de acumulación                  |
//+------------------------------------------------------------------+
double CAccumulationZones::CalculateLevelStrength(int index, int touches, datetime firstTouch) {
   double strength = 5.0; // Valor base
   
   // Factor 1: Número de barras (más barras = más fuerte, pero no demasiadas)
   int optimalBars = 8;
   
   if(index < m_zonesCount) {
      if(m_zones[index].barCount < optimalBars) {
         strength += (double)m_zones[index].barCount / optimalBars * 2.0;
      } else if(m_zones[index].barCount > optimalBars * 2) {
         strength -= (double)(m_zones[index].barCount - optimalBars * 2) / optimalBars * 1.0;
      } else {
         strength += 2.0;
      }
      
      // Factor 2: Ratio de volatilidad (menor volatilidad = mejor acumulación)
      if(m_zones[index].volatilityRatio < 0.7) {
         strength += (0.7 - m_zones[index].volatilityRatio) * 10.0; // Máximo 3 puntos
      } else if(m_zones[index].volatilityRatio > 1.0) {
         strength -= (m_zones[index].volatilityRatio - 1.0) * 5.0;
      }
   }
   
   // Factor 3: Cercanía al precio actual
   double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double zoneCenter = 0.0;
   
   if(index < m_zonesCount) {
      zoneCenter = (m_zones[index].highPrice + m_zones[index].lowPrice) / 2;
   }
   
   double currentATR = GetCurrentATR();
   if(currentATR > 0) {
      double distance = MathAbs(currentPrice - zoneCenter) / currentATR;
      
      if(distance < 2.0) {
         strength += (2.0 - distance) * 1.0; // Máximo 2 puntos
      }
   }
   
   // Limitar a rango 0-10
   return MathMax(0.0, MathMin(strength, 10.0));
}

//+------------------------------------------------------------------+
//| METODOS PUBLICOS ADICIONALES                                     |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CAccumulationZones::GetZoneDirection(double currentPrice)
{
    for(int i = 0; i < m_zonesCount; i++)
    {
        if(!m_zones[i].active || !m_zones[i].confirmed)
            continue;

        if(m_zones[i].levelType == SR_SUPPORT &&
           currentPrice >= m_zones[i].lowPrice &&
           currentPrice <= m_zones[i].highPrice)
        {
            return TREND_UP;
        }
        else if(m_zones[i].levelType == SR_RESISTANCE &&
                currentPrice >= m_zones[i].lowPrice &&
                currentPrice <= m_zones[i].highPrice)
        {
            return TREND_DOWN;
        }
    }
    return TREND_NONE;
}
//+------------------------------------------------------------------+
double CAccumulationZones::GetZoneConfidence()
{
    double maxStrength = 0.0;
    for(int i = 0; i < m_zonesCount; i++)
    {
        if(m_zones[i].active && m_zones[i].confirmed)
        {
            maxStrength = MathMax(maxStrength, m_zones[i].strength);
        }
    }
    // Normalize: strength is 0..10 -> return 0..1
    return (maxStrength <= 0.0 ? 0.0 : maxStrength / 10.0);
}

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Calcula el volumen promedio de todas las zonas activas           |
//+------------------------------------------------------------------+
double CAccumulationZones::GetAverageVolume()
{
   if(m_zonesCount == 0)
      return 0.0;
   double sum = 0.0;
   for(int i = 0; i < m_zonesCount; i++)
      sum += m_zones[i].volumeAvg;
   return sum / m_zonesCount;
}

//+------------------------------------------------------------------+
//| Devuelve dirección y confianza basada en zonas de acumulación    |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CAccumulationZones::GetVoteDirection(double &confidence)
{
    ENUM_TREND_DIRECTION dir = GetZoneDirection(SymbolInfoDouble(Symbol(), SYMBOL_BID));
    confidence = GetZoneConfidence();
    return dir;
}

// --- NUEVA IMPLEMENTACIÓN ---
double CalculateVolatilityRatio(double highPrice, double lowPrice)
{
   if(highPrice <= 0 || lowPrice <= 0 || highPrice <= lowPrice)
   {
      PrintFormat("CalculateVolatilityRatio: parámetros inválidos (high=%.5f low=%.5f)", highPrice, lowPrice);
      return 0.0;
   }
   double midpoint = (highPrice + lowPrice) * 0.5;
   double rangePct = (highPrice - lowPrice) / midpoint;
   rangePct = MathMin(MathMax(rangePct, 0.0), 1.0);
   return rangePct;
}
#endif // ACCUMULATION_ZONES_MQH