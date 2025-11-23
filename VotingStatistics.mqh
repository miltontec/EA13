//+------------------------------------------------------------------+
//| VotingStatistics_Enhanced.mqh - Sistema Adaptativo Completo v5.0|
//| Sistema inteligente con aprendizaje diferenciado BUY/SELL       |
//| Copyright 2025 - Advanced Trading Systems                        |
//+------------------------------------------------------------------+
#ifndef VOTING_STATISTICS_ENHANCED_MQH
#define VOTING_STATISTICS_ENHANCED_MQH

#property copyright "Advanced Trading System 2025"
#property version   "5.00"
#property strict

#include <RegimeDetectionSystem.mqh>

//+------------------------------------------------------------------+
//| ENUMERACIONES MEJORADAS                                          |
//+------------------------------------------------------------------+

// Sesiones de trading con overlaps
enum ENUM_TRADING_SESSION {
    SESSION_ASIA      = 0,  // 00:00-08:00 GMT
    SESSION_LONDON    = 1,  // 08:00-16:00 GMT
    SESSION_NY        = 2,  // 13:00-22:00 GMT
    SESSION_OVERLAP_EU_US = 3,  // 13:00-16:00 GMT
    SESSION_OVERNIGHT = 4   // 22:00-00:00 GMT
};

// Niveles de volatilidad expandidos
enum ENUM_VOLATILITY_LEVEL {
    VOL_ULTRA_LOW  = 0,  // ATR < percentil 20
    VOL_LOW        = 1,  // ATR percentil 20-40
    VOL_MEDIUM     = 2,  // ATR percentil 40-60
    VOL_HIGH       = 3,  // ATR percentil 60-80
    VOL_EXTREME    = 4   // ATR > percentil 80
};

// Dirección del mercado con neutral
enum ENUM_MARKET_DIRECTION {
    DIR_STRONG_BEARISH = -2,  // Fuertemente bajista
    DIR_BEARISH = -1,         // Bajista
    DIR_NEUTRAL = 0,          // Lateral/Ranging
    DIR_BULLISH = 1,          // Alcista
    DIR_STRONG_BULLISH = 2    // Fuertemente alcista
};

// Dirección de voto
enum ENUM_VOTE_DIRECTION {
    VOTE_STRONG_SELL = -2,
    VOTE_SELL = -1,
    VOTE_NEUTRAL = 0,
    VOTE_BUY = 1,
    VOTE_STRONG_BUY = 2
};

// Tipos de componentes/agentes del sistema
enum ENUM_COMPONENT_TYPE {
    COMPONENT_SUPPORT_RESIST = 0,
    COMPONENT_ACCUM_ZONES = 1,
    COMPONENT_PATTERN_MEMORY = 2,
    COMPONENT_BREAKOUT_DETECT = 3,
    COMPONENT_INSTITUTIONAL = 4,
    COMPONENT_BULLISH = 10,    // Para compatibilidad con otros usos
    COMPONENT_BEARISH = 11,
    COMPONENT_NEUTRAL = 12
};

// Tipos de indicadores (renombrados para evitar conflicto con built-ins)
enum ENUM_INDICATOR_TYPE {
    IND_SUPPORT_RESIST = 0,
    IND_ML_SYSTEM = 1,
    IND_MOMENTUM_VOTING = 2,  // Renombrado de IND_MOMENTUM
    IND_RSI_VOTING = 3,       // Renombrado de IND_RSI
    IND_VOLUME = 4,
    IND_PATTERN = 5,
    IND_INSTITUTIONAL = 6,
    IND_SENTIMENT = 7,
    IND_TOTAL = 8
};

// Nivel de expertise mejorado
enum ENUM_EXPERTISE_LEVEL {
    EXPERTISE_NONE      = 0,  // Sin datos
    EXPERTISE_LEARNING  = 1,  // < 20 trades
    EXPERTISE_NOVICE    = 2,  // WR 45-52%, 20-50 trades
    EXPERTISE_COMPETENT = 3,  // WR 52-58%, 50-100 trades
    EXPERTISE_PROFICIENT = 4, // WR 58-62%, 100-200 trades
    EXPERTISE_EXPERT    = 5,  // WR 62-68%, 200-500 trades
    EXPERTISE_MASTER    = 6,  // WR > 68%, > 500 trades
    EXPERTISE_GRANDMASTER = 7 // WR > 72%, > 1000 trades, Sharpe > 2.0
};

// Velocidad de aprendizaje
enum ENUM_LEARNING_SPEED {
    LEARN_ULTRA_SLOW = 0,   // Factor 0.95
    LEARN_SLOW = 1,         // Factor 0.98
    LEARN_NORMAL = 2,       // Factor 1.0
    LEARN_FAST = 3,         // Factor 1.05
    LEARN_ULTRA_FAST = 4    // Factor 1.1
};

//+------------------------------------------------------------------+
//| ESTRUCTURAS DE DATOS MEJORADAS                                   |
//+------------------------------------------------------------------+

// Métricas de performance por dirección
struct DirectionalMetrics {
    // Métricas BUY
    int buyTrades;
    int buyWins;
    double buyProfit;
    double buyAvgWin;
    double buyAvgLoss;
    double buyWinRate;
    double buyProfitFactor;
    double buyExpectancy;
    double buyMaxDrawdown;
    int buyCurrentStreak;
    int buyMaxWinStreak;
    int buyMaxLossStreak;
    double buyGrossProfit;  // FIX: Tracking for robust Profit Factor
    double buyGrossLoss;    // FIX: Tracking for robust Profit Factor

    // Métricas SELL
    int sellTrades;
    int sellWins;
    double sellProfit;
    double sellAvgWin;
    double sellAvgLoss;
    double sellWinRate;
    double sellProfitFactor;
    double sellExpectancy;
    double sellMaxDrawdown;
    int sellCurrentStreak;
    int sellMaxWinStreak;
    int sellMaxLossStreak;
    double sellGrossProfit; // FIX: Tracking for robust Profit Factor
    double sellGrossLoss;   // FIX: Tracking for robust Profit Factor
    
    // Tiempos promedio
    int avgBarsInWinningTrade;
    int avgBarsInLosingTrade;
    double avgMAE;  // Maximum Adverse Excursion
    double avgMFE;  // Maximum Favorable Excursion
    
    // Momentum de performance
    double performanceMomentum;  // -1 a 1, negativo = empeorando
    double recentWinRate;        // Win rate últimos 20 trades
    double confidenceScore;       // 0-1, confianza general
    
    void Initialize() {
        buyTrades = sellTrades = 0;
        buyWins = sellWins = 0;
        buyProfit = sellProfit = 0.0;
        buyAvgWin = sellAvgWin = 0.0;
        buyAvgLoss = sellAvgLoss = 0.0;
        buyWinRate = sellWinRate = 0.5;
        buyProfitFactor = sellProfitFactor = 1.0;
        buyExpectancy = sellExpectancy = 0.0;
        buyMaxDrawdown = sellMaxDrawdown = 0.0;
        buyCurrentStreak = sellCurrentStreak = 0;
        buyMaxWinStreak = sellMaxWinStreak = 0;
        buyMaxLossStreak = sellMaxLossStreak = 0;
        buyGrossProfit = sellGrossProfit = 0.0;  // FIX: Initialize gross profit/loss
        buyGrossLoss = sellGrossLoss = 0.0;
        avgBarsInWinningTrade = avgBarsInLosingTrade = 0;
        avgMAE = avgMFE = 0.0;
        performanceMomentum = 0.0;
        recentWinRate = 0.5;
        confidenceScore = 0.5;
    }
    
    void UpdateMetrics(ENUM_VOTE_DIRECTION direction, bool won, double profit, int bars, double mae, double mfe) {
        if(direction == VOTE_BUY || direction == VOTE_STRONG_BUY) {
            buyTrades++;
            buyProfit += profit;

            if(won) {
                buyWins++;
                buyAvgWin = ((buyAvgWin * (buyWins - 1)) + profit) / buyWins;
                buyGrossProfit += profit;  // FIX: Track gross profit
                buyCurrentStreak = (buyCurrentStreak >= 0) ? buyCurrentStreak + 1 : 1;
                buyMaxWinStreak = MathMax(buyMaxWinStreak, buyCurrentStreak);
            } else {
                int losses = buyTrades - buyWins;
                buyAvgLoss = ((buyAvgLoss * (losses - 1)) + MathAbs(profit)) / losses;
                buyGrossLoss += MathAbs(profit);  // FIX: Track gross loss
                buyCurrentStreak = (buyCurrentStreak <= 0) ? buyCurrentStreak - 1 : -1;
                buyMaxLossStreak = MathMax(buyMaxLossStreak, MathAbs(buyCurrentStreak));
            }

            // FIX 1: Laplace Smoothing for Win Rate (Bayesian estimator)
            // Formula: (Wins + 1) / (TotalTrades + 2)
            // Prevents extreme values (0% or 100%) with few samples
            buyWinRate = (double)(buyWins + 1) / (double)(buyTrades + 2);

            // FIX 2: Robust Profit Factor based on Gross Profit/Loss
            // True PF = Sum(GrossProfit) / Sum(GrossLoss)
            if(buyGrossLoss > 0) {
                buyProfitFactor = buyGrossProfit / buyGrossLoss;
            } else {
                buyProfitFactor = (buyGrossProfit > 0) ? 10.0 : 1.0;  // Cap at 10.0 to avoid infinity
            }

            // FIX 3: Expectancy calculation (valid formula)
            // NOTE: For multi-asset normalization, consider dividing by ATR or current price
            buyExpectancy = (buyWinRate * buyAvgWin) - ((1.0 - buyWinRate) * buyAvgLoss);
            
        } else if(direction == VOTE_SELL || direction == VOTE_STRONG_SELL) {
            sellTrades++;
            sellProfit += profit;

            if(won) {
                sellWins++;
                sellAvgWin = ((sellAvgWin * (sellWins - 1)) + profit) / sellWins;
                sellGrossProfit += profit;  // FIX: Track gross profit
                sellCurrentStreak = (sellCurrentStreak >= 0) ? sellCurrentStreak + 1 : 1;
                sellMaxWinStreak = MathMax(sellMaxWinStreak, sellCurrentStreak);
            } else {
                int losses = sellTrades - sellWins;
                sellAvgLoss = ((sellAvgLoss * (losses - 1)) + MathAbs(profit)) / losses;
                sellGrossLoss += MathAbs(profit);  // FIX: Track gross loss
                sellCurrentStreak = (sellCurrentStreak <= 0) ? sellCurrentStreak - 1 : -1;
                sellMaxLossStreak = MathMax(sellMaxLossStreak, MathAbs(sellCurrentStreak));
            }

            // FIX 1: Laplace Smoothing for Win Rate (Bayesian estimator)
            // Formula: (Wins + 1) / (TotalTrades + 2)
            // Prevents extreme values (0% or 100%) with few samples
            sellWinRate = (double)(sellWins + 1) / (double)(sellTrades + 2);

            // FIX 2: Robust Profit Factor based on Gross Profit/Loss
            // True PF = Sum(GrossProfit) / Sum(GrossLoss)
            if(sellGrossLoss > 0) {
                sellProfitFactor = sellGrossProfit / sellGrossLoss;
            } else {
                sellProfitFactor = (sellGrossProfit > 0) ? 10.0 : 1.0;  // Cap at 10.0 to avoid infinity
            }

            // FIX 3: Expectancy calculation (valid formula)
            // NOTE: For multi-asset normalization, consider dividing by ATR or current price
            sellExpectancy = (sellWinRate * sellAvgWin) - ((1.0 - sellWinRate) * sellAvgLoss);
        }
        
        // Actualizar tiempos y excursiones
        if(won) {
            avgBarsInWinningTrade = ((avgBarsInWinningTrade * (buyWins + sellWins - 1)) + bars) / (buyWins + sellWins);
        } else {
            int totalLosses = (buyTrades - buyWins) + (sellTrades - sellWins);
            avgBarsInLosingTrade = ((avgBarsInLosingTrade * (totalLosses - 1)) + bars) / totalLosses;
        }
        
        avgMAE = ((avgMAE * (buyTrades + sellTrades - 1)) + mae) / (buyTrades + sellTrades);
        avgMFE = ((avgMFE * (buyTrades + sellTrades - 1)) + mfe) / (buyTrades + sellTrades);
        
        // Calcular momentum de performance
        CalculatePerformanceMomentum();
        
        // Actualizar score de confianza
        UpdateConfidenceScore();
    }
    
    void CalculatePerformanceMomentum() {
        // FIX 4: Apply Laplace Smoothing to overall win rate as well
        // Comparar performance reciente vs histórica
        int totalTrades = buyTrades + sellTrades;
        int totalWins = buyWins + sellWins;
        double overallWinRate = (double)(totalWins + 1) / (double)(totalTrades + 2);

        performanceMomentum = (recentWinRate - overallWinRate) * 2.0; // Rango -1 a 1
        performanceMomentum = MathMax(-1.0, MathMin(1.0, performanceMomentum));
    }
    
    void UpdateConfidenceScore() {
        // FIX 5: Universal Normalization for all score components
        double wrScore = (buyWinRate + sellWinRate) / 2.0;

        // Profit Factor normalized (2.5 PF is considered excellent)
        double pfAvg = (buyProfitFactor + sellProfitFactor) / 2.0;
        double pfScore = MathMin(1.0, pfAvg / 2.5);

        // FIX: Use Tanh for asset-independent expectancy normalization
        // Tanh maps (-inf, +inf) to (-1, 1), we normalize by dividing by a reference scale (100)
        double totalExp = buyExpectancy + sellExpectancy;
        double expScore = MathTanh(totalExp / 100.0);  // Tanh output between -1 and 1
        expScore = MathMax(0.0, expScore);  // Only value positive expectancy

        double momentumScore = (performanceMomentum + 1.0) / 2.0;

        // Balanced weighting: More emphasis on consistency (WR) and Momentum
        confidenceScore = (wrScore * 0.35) + (pfScore * 0.25) + (expScore * 0.20) + (momentumScore * 0.20);
        confidenceScore = MathMax(0.1, MathMin(1.0, confidenceScore));
    }
    
    double GetDirectionalStrength(ENUM_VOTE_DIRECTION direction) {
        if(direction == VOTE_BUY || direction == VOTE_STRONG_BUY) {
            return buyWinRate * buyProfitFactor * confidenceScore;
        } else if(direction == VOTE_SELL || direction == VOTE_STRONG_SELL) {
            return sellWinRate * sellProfitFactor * confidenceScore;
        }
        return 0.5;
    }
    
    // ============ MÉTODOS AGREGADOS PARA MÉTRICAS TOTALES ============
    
    // Obtener total de trades (BUY + SELL)
    int GetTotalTrades() {
        return buyTrades + sellTrades;
    }
    
    // Obtener total de wins (BUY + SELL)
    int GetTotalWins() {
        return buyWins + sellWins;
    }
    
    // Obtener profit total (BUY + SELL)
    double GetTotalProfit() {
        return buyProfit + sellProfit;
    }
    
    // Obtener WinRate total combinado (BUY + SELL)
    // FIX: Usar Laplace Smoothing consistente con buyWinRate/sellWinRate
    double GetTotalWinRate() {
        int totalTrades = GetTotalTrades();
        int totalWins = GetTotalWins();
        // Laplace smoothing: (Wins + 1) / (Trades + 2)
        return (double)(totalWins + 1) / (double)(totalTrades + 2);
    }
    
    // Obtener Profit Factor total combinado
    // FIX: Usar Gross Profit/Loss acumulados (consistente con buyProfitFactor/sellProfitFactor)
    double GetTotalProfitFactor() {
        // Sumar gross profit y gross loss de ambas direcciones
        double totalGrossProfit = buyGrossProfit + sellGrossProfit;
        double totalGrossLoss = buyGrossLoss + sellGrossLoss;

        // Calcular PF real: GrossProfit / GrossLoss
        if(totalGrossLoss > 0) {
            return totalGrossProfit / totalGrossLoss;
        } else {
            // Sin pérdidas: retornar 10.0 (cap) si hay profit, 0.0 si no hay nada
            return (totalGrossProfit > 0) ? 10.0 : 0.0;
        }
    }
    
    // Obtener Expectancy total combinado
    double GetTotalExpectancy() {
        double totalWinRate = GetTotalWinRate();
        double totalAvgWin = 0.0;
        double totalAvgLoss = 0.0;
        
        int totalWins = GetTotalWins();
        int totalTrades = GetTotalTrades();
        int totalLosses = totalTrades - totalWins;
        
        if(buyWins > 0 && sellWins > 0) {
            totalAvgWin = (buyAvgWin * buyWins + sellAvgWin * sellWins) / totalWins;
        } else if(buyWins > 0) {
            totalAvgWin = buyAvgWin;
        } else if(sellWins > 0) {
            totalAvgWin = sellAvgWin;
        }
        
        int buyLosses = buyTrades - buyWins;
        int sellLosses = sellTrades - sellWins;
        
        if(buyLosses > 0 && sellLosses > 0) {
            totalAvgLoss = (buyAvgLoss * buyLosses + sellAvgLoss * sellLosses) / totalLosses;
        } else if(buyLosses > 0) {
            totalAvgLoss = buyAvgLoss;
        } else if(sellLosses > 0) {
            totalAvgLoss = sellAvgLoss;
        }
        
        return (totalWinRate * totalAvgWin) - ((1 - totalWinRate) * totalAvgLoss);
    }
};

// Patrón de error contextual
struct ContextualErrorPattern {
    ENUM_INDICATOR_TYPE indicator;
    ENUM_TRADING_SESSION session;
    ENUM_VOLATILITY_LEVEL volatility;
    ENUM_MARKET_DIRECTION marketDir;
    ENUM_VOTE_DIRECTION voteDir;
    
    int errorCount;
    double avgLossSize;
    double errorRate;
    datetime lastError;
    int consecutiveErrors;
    double penaltyFactor;  // 0.1 a 1.0
    
    // Recovery tracking
    int successesSinceError;
    double recoveryRate;
    bool isRecovering;
    
    void Initialize() {
        errorCount = 0;
        avgLossSize = 0.0;
        errorRate = 0.0;
        lastError = 0;
        consecutiveErrors = 0;
        penaltyFactor = 1.0;
        successesSinceError = 0;
        recoveryRate = 0.0;
        isRecovering = false;
    }
    
    void RegisterError(double lossSize) {
        errorCount++;
        avgLossSize = ((avgLossSize * (errorCount - 1)) + lossSize) / errorCount;
        lastError = TimeCurrent();
        consecutiveErrors++;
        successesSinceError = 0;
        isRecovering = false;
        
        // Aplicar penalización progresiva
        penaltyFactor = MathMax(0.1, penaltyFactor - (consecutiveErrors * 0.1));
    }
    
    void RegisterSuccess() {
        successesSinceError++;
        consecutiveErrors = 0;
        
        // Iniciar recuperación después de 3 éxitos
        if(successesSinceError >= 3 && !isRecovering) {
            isRecovering = true;
        }
        
        // Recuperación gradual del factor de penalización
        if(isRecovering) {
            penaltyFactor = MathMin(1.0, penaltyFactor + 0.05);
            
            // Recuperación completa después de 10 éxitos
            if(successesSinceError >= 10) {
                penaltyFactor = 1.0;
                isRecovering = false;
            }
        }
    }
};

// Correlación entre indicadores
struct IndicatorCorrelation {
    ENUM_INDICATOR_TYPE indicator1;
    ENUM_INDICATOR_TYPE indicator2;
    double correlation;      // -1 a 1
    double agreementRate;    // 0 a 1
    int sampleCount;
    
    // Tracking de conflictos
    int conflictCount;
    int conflictWins;        // Veces que el conflicto resultó correcto
    double conflictWinRate;
    
    void Initialize() {
        correlation = 0.0;
        agreementRate = 0.5;
        sampleCount = 0;
        conflictCount = 0;
        conflictWins = 0;
        conflictWinRate = 0.5;
    }
    
    void UpdateCorrelation(double value1, double value2, bool wasCorrect) {
        sampleCount++;
        
        // Actualizar correlación usando método incremental
        if(sampleCount > 1) {
            double delta = (value1 * value2 - correlation) / sampleCount;
            correlation += delta;
            correlation = MathMax(-1.0, MathMin(1.0, correlation));
        }
        
        // Actualizar agreement rate
        bool agreed = (value1 > 0 && value2 > 0) || (value1 < 0 && value2 < 0);
        agreementRate = ((agreementRate * (sampleCount - 1)) + (agreed ? 1.0 : 0.0)) / sampleCount;
        
        // Tracking de conflictos
        if(!agreed) {
            conflictCount++;
            if(wasCorrect) conflictWins++;
            conflictWinRate = (conflictCount > 0) ? (double)conflictWins / conflictCount : 0.5;
        }
    }
};

// Contexto de mercado expandido
struct EnhancedMarketContext {
    // Temporal
    ENUM_TRADING_SESSION session;
    int hourGMT;
    int dayOfWeek;
    int weekOfMonth;
    int monthOfYear;
    datetime timestamp;
    
    // Volatilidad
    ENUM_VOLATILITY_LEVEL volatility;
    double atr;
    double atrPercentile;
    double volatilityChange;  // vs período anterior
    
    // Dirección y tendencia
    ENUM_MARKET_DIRECTION direction;
    double trendStrength;      // 0-1
    double momentum;
    int trendAge;             // Barras en tendencia actual
    
    // Régimen de mercado
    ENUM_MARKET_REGIME regime;
    double regimeConfidence;
    int regimeAge;
    
    // Liquidez y volumen
    double volumeRatio;       // vs promedio
    double spread;
    double liquidityScore;    // 0-1
    
    // Eventos y noticias
    bool hasNewsEvent;
    int newsImpact;          // 1=Low, 2=Medium, 3=High
    bool isHoliday;
    
    // Score contextual único
    string contextID;
    double contextComplexity; // 0-1, qué tan difícil es el contexto
    
    void Initialize() {
        session = SESSION_ASIA;
        hourGMT = 0;
        dayOfWeek = 0;
        weekOfMonth = 1;
        monthOfYear = 1;
        timestamp = 0;
        
        volatility = VOL_MEDIUM;
        atr = 0.0;
        atrPercentile = 50.0;
        volatilityChange = 0.0;
        
        direction = DIR_NEUTRAL;
        trendStrength = 0.0;
        momentum = 0.0;
        trendAge = 0;
        
        regime = REGIME_RANGING;
        regimeConfidence = 0.5;
        regimeAge = 0;
        
        volumeRatio = 1.0;
        spread = 0.0;
        liquidityScore = 1.0;
        
        hasNewsEvent = false;
        newsImpact = 0;
        isHoliday = false;
        
        contextID = "";
        contextComplexity = 0.5;
    }
    
    string GenerateContextID() {
        contextID = StringFormat("%d_%d_%d_%d_%d", 
            session, volatility, direction, regime, newsImpact);
        return contextID;
    }
    
    double CalculateComplexity() {
        double complexity = 0.0;
        
        // Alta volatilidad = más complejo
        complexity += (volatility >= VOL_HIGH) ? 0.2 : 0.0;
        
        // Cambio de régimen = más complejo
        complexity += (regimeAge < 20) ? 0.2 : 0.0;
        
        // Baja liquidez = más complejo
        complexity += (liquidityScore < 0.5) ? 0.2 : 0.0;
        
        // Eventos de noticias = más complejo
        complexity += hasNewsEvent ? (newsImpact * 0.1) : 0.0;
        
        // Sesiones overlap = más complejo
        complexity += (session == SESSION_OVERLAP_EU_US) ? 0.1 : 0.0;
        
        contextComplexity = MathMin(1.0, complexity);
        return contextComplexity;
    }
};

// Celda de performance contextual mejorada
struct EnhancedPerformanceCell {
    DirectionalMetrics metrics;
    ENUM_EXPERTISE_LEVEL expertiseLevel;
    datetime lastUpdate;
    int sampleSize;
    
    // Tracking de patrones
    int winStreaks[10];       // Histograma de rachas ganadoras
    int lossStreaks[10];      // Histograma de rachas perdedoras
    double avgRecoveryTime;   // Tiempo promedio para recuperar pérdidas
    
    // Análisis de timing
    int bestEntryHour;        // Mejor hora para entrar
    int worstEntryHour;       // Peor hora para entrar
    double hourlyWinRate[24]; // Win rate por hora
    
    void Initialize() {
        metrics.Initialize();
        expertiseLevel = EXPERTISE_NONE;
        lastUpdate = 0;
        sampleSize = 0;
        avgRecoveryTime = 0.0;
        bestEntryHour = -1;
        worstEntryHour = -1;
        
        for(int i = 0; i < 10; i++) {
            winStreaks[i] = 0;
            lossStreaks[i] = 0;
        }
        
        for(int i = 0; i < 24; i++) {
            hourlyWinRate[i] = 0.5;
        }
    }
    
    void UpdateExpertiseLevel() {
        int totalTrades = metrics.GetTotalTrades();
        double avgWinRate = metrics.GetTotalWinRate();
        double avgPF = metrics.GetTotalProfitFactor();
        
        if(totalTrades < 20) {
            expertiseLevel = EXPERTISE_LEARNING;
        } else if(totalTrades < 50) {
            expertiseLevel = (avgWinRate > 0.52) ? EXPERTISE_NOVICE : EXPERTISE_LEARNING;
        } else if(totalTrades < 100) {
            if(avgWinRate > 0.58 && avgPF > 1.3) expertiseLevel = EXPERTISE_COMPETENT;
            else expertiseLevel = EXPERTISE_NOVICE;
        } else if(totalTrades < 200) {
            if(avgWinRate > 0.62 && avgPF > 1.5) expertiseLevel = EXPERTISE_PROFICIENT;
            else expertiseLevel = EXPERTISE_COMPETENT;
        } else if(totalTrades < 500) {
            if(avgWinRate > 0.65 && avgPF > 1.8) expertiseLevel = EXPERTISE_EXPERT;
            else expertiseLevel = EXPERTISE_PROFICIENT;
        } else if(totalTrades < 1000) {
            if(avgWinRate > 0.68 && avgPF > 2.0) expertiseLevel = EXPERTISE_MASTER;
            else expertiseLevel = EXPERTISE_EXPERT;
        } else {
            if(avgWinRate > 0.72 && avgPF > 2.5) expertiseLevel = EXPERTISE_GRANDMASTER;
            else expertiseLevel = EXPERTISE_MASTER;
        }
    }
    
    double GetExpertiseMultiplier() {
        switch(expertiseLevel) {
            case EXPERTISE_GRANDMASTER: return 2.0;
            case EXPERTISE_MASTER: return 1.8;
            case EXPERTISE_EXPERT: return 1.5;
            case EXPERTISE_PROFICIENT: return 1.3;
            case EXPERTISE_COMPETENT: return 1.1;
            case EXPERTISE_NOVICE: return 0.9;
            case EXPERTISE_LEARNING: return 0.7;
            default: return 0.5;
        }
    }
};

// Especialización del indicador mejorada
struct EnhancedIndicatorSpecialization {
    ENUM_INDICATOR_TYPE indicatorType;
    string indicatorName;
    
    // Especialización por contexto
    string topContexts[5];         // Top 5 contextos donde es experto
    double contextScores[5];       // Scores en esos contextos
    
    // Métricas globales
    DirectionalMetrics globalMetrics;
    int globalRank;                // Ranking entre todos los indicadores
    double trustScore;             // 0-1, qué tanto confiar en este indicador
    
    // Velocidad de aprendizaje
    ENUM_LEARNING_SPEED learningSpeed;
    double adaptationRate;         // Qué tan rápido se adapta a cambios
    
    // Especialización por tipo de mercado
    double trendingMarketScore;    // Performance en trending
    double rangingMarketScore;     // Performance en ranging
    double volatileMarketScore;    // Performance en volatile
    double calmMarketScore;        // Performance en calmo
    
    void Initialize() {
        indicatorType = IND_SUPPORT_RESIST;
        indicatorName = "";
        globalRank = 0;
        trustScore = 0.5;
        learningSpeed = LEARN_NORMAL;
        adaptationRate = 1.0;
        
        globalMetrics.Initialize();
        
        for(int i = 0; i < 5; i++) {
            topContexts[i] = "";
            contextScores[i] = 0.0;
        }
        
        trendingMarketScore = 0.5;
        rangingMarketScore = 0.5;
        volatileMarketScore = 0.5;
        calmMarketScore = 0.5;
    }
    
    void UpdateMarketTypeScores(ENUM_MARKET_REGIME regime, double performance) {
        double alpha = GetLearningAlpha();
        
        switch(regime) {
            case REGIME_TRENDING_UP:
            case REGIME_TRENDING_DOWN:
                trendingMarketScore = (1 - alpha) * trendingMarketScore + alpha * performance;
                break;

            case REGIME_RANGING:
                rangingMarketScore = (1 - alpha) * rangingMarketScore + alpha * performance;
                break;

            case REGIME_VOLATILE:
            case REGIME_CRISIS:
                volatileMarketScore = (1 - alpha) * volatileMarketScore + alpha * performance;
                break;

            default:
                calmMarketScore = (1 - alpha) * calmMarketScore + alpha * performance;
        }
    }
    
    double GetLearningAlpha() {
        switch(learningSpeed) {
            case LEARN_ULTRA_FAST: return 0.3;
            case LEARN_FAST: return 0.2;
            case LEARN_NORMAL: return 0.1;
            case LEARN_SLOW: return 0.05;
            case LEARN_ULTRA_SLOW: return 0.02;
            default: return 0.1;
        }
    }
    
    bool IsExpertIn(string contextID) {
        for(int i = 0; i < 5; i++) {
            if(topContexts[i] == contextID && contextScores[i] > 0.65) {
                return true;
            }
        }
        return false;
    }
    
    void UpdateTrustScore() {
        // Trust basado en consistencia y performance
        double consistency = 1.0 - MathAbs(globalMetrics.performanceMomentum);
        double performance = globalMetrics.confidenceScore;
        double experience = MathMin(1.0, globalMetrics.GetTotalTrades() / 100.0);
        
        trustScore = consistency * 0.3 + performance * 0.5 + experience * 0.2;
        trustScore = MathMax(0.1, MathMin(1.0, trustScore));
    }
};

// Peso dinámico con justificación
struct EnhancedDynamicWeight {
    ENUM_INDICATOR_TYPE indicator;
    double baseWeight;         // Peso base del indicador
    double contextBonus;       // Bonus por contexto favorable
    double performanceBonus;   // Bonus por buen performance
    double penaltyFactor;      // Penalización por errores
    double finalWeight;        // Peso final calculado
    bool isActive;            // Si el indicador está activo
    string reasoning;         // Explicación del peso
    
    void Initialize() {
        baseWeight = 0.2;
        contextBonus = 0.0;
        performanceBonus = 0.0;
        penaltyFactor = 1.0;
        finalWeight = 0.2;
        isActive = true;
        reasoning = "";
    }
    
    void CalculateFinalWeight() {
        finalWeight = baseWeight * (1 + contextBonus + performanceBonus) * penaltyFactor;
        finalWeight = MathMax(0.01, MathMin(1.0, finalWeight));
        
        // Generar reasoning
        reasoning = StringFormat("Base:%.2f Context:+%.2f Perf:+%.2f Penalty:x%.2f = %.2f",
            baseWeight, contextBonus, performanceBonus, penaltyFactor, finalWeight);
    }
};

//+------------------------------------------------------------------+
//| CLASE PRINCIPAL DEL SISTEMA VOTACIÓN ADAPTATIVO                 |
//+------------------------------------------------------------------+
class CEnhancedAdaptiveVotingSystem {
private:
    // Matriz de performance multidimensional
    EnhancedPerformanceCell m_performanceMatrix[8][5][5][5]; // [Indicador][Sesión][Volatilidad][Dirección]
    
    // Especializaciones de indicadores
    EnhancedIndicatorSpecialization m_specializations[8];
    
    // Patrones de error
    ContextualErrorPattern m_errorPatterns[];
    
    // Correlaciones entre indicadores
    IndicatorCorrelation m_correlations[28]; // C(8,2) = 28 pares posibles
    
    // Configuración del sistema
    int m_adaptivePeriodBars;      // Período base para adaptación
    double m_volatilityMultiplier; // Multiplicador por volatilidad
    datetime m_systemStartTime;
    datetime m_lastResetTime;
    datetime m_lastOptimizationTime;
    
    // Estadísticas globales
    int m_totalSystemTrades;
    double m_totalSystemProfit;
    double m_systemWinRate;
    double m_systemSharpe;
    
    // Estado actual del mercado
    EnhancedMarketContext m_currentContext;
    
    // Memoria de decisiones
    struct DecisionMemory {
        datetime timestamp;
        string contextID;
        ENUM_VOTE_DIRECTION decision;
        double confidence;
        string reasoning;
        double result;
        bool wasCorrect;
    } m_decisionHistory[];
    
public:
    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+
    CEnhancedAdaptiveVotingSystem() {
        m_adaptivePeriodBars = 500;
        m_volatilityMultiplier = 1.0;
        m_systemStartTime = TimeCurrent();
        m_lastResetTime = TimeCurrent();
        m_lastOptimizationTime = TimeCurrent();
        m_totalSystemTrades = 0;
        m_totalSystemProfit = 0.0;
        m_systemWinRate = 0.5;
        m_systemSharpe = 0.0;
        
        Initialize();
    }
    
    //+------------------------------------------------------------------+
    //| Inicialización del sistema                                      |
    //+------------------------------------------------------------------+
    void Initialize() {
        // Inicializar matriz de performance
        for(int ind = 0; ind < 8; ind++) {
            for(int ses = 0; ses < 5; ses++) {
                for(int vol = 0; vol < 5; vol++) {
                    for(int dir = 0; dir < 5; dir++) {
                        m_performanceMatrix[ind][ses][vol][dir].Initialize();
                    }
                }
            }
        }
        
        // Inicializar especializaciones
        string indicatorNames[] = {
            "Support/Resistance", "ML System", "Momentum", "RSI", 
            "Volume", "Pattern", "Institutional", "Sentiment"
        };
        
        for(int i = 0; i < 8; i++) {
            m_specializations[i].Initialize();
            m_specializations[i].indicatorType = (ENUM_INDICATOR_TYPE)i;
            m_specializations[i].indicatorName = indicatorNames[i];
        }
        
        // Inicializar correlaciones
        int corrIndex = 0;
        for(int i = 0; i < 8; i++) {
            for(int j = i + 1; j < 8; j++) {
                m_correlations[corrIndex].Initialize();
                m_correlations[corrIndex].indicator1 = (ENUM_INDICATOR_TYPE)i;
                m_correlations[corrIndex].indicator2 = (ENUM_INDICATOR_TYPE)j;
                corrIndex++;
            }
        }
        
        // Cargar datos históricos si existen
        LoadHistoricalData();
        
        Print("✅ Sistema de Votación Adaptativo Enhanced inicializado");
    }
    
    //+------------------------------------------------------------------+
    //| Obtener pesos dinámicos para el contexto actual                 |
    //+------------------------------------------------------------------+
    bool GetDynamicWeights(EnhancedDynamicWeight &weights[], EnhancedMarketContext &context) {
        ArrayResize(weights, 8);
        m_currentContext = context;
        m_currentContext.GenerateContextID();
        m_currentContext.CalculateComplexity();
        
        // Verificar si necesitamos reseteo adaptativo
        CheckAdaptiveReset();
        
        for(int i = 0; i < 8; i++) {
            weights[i].Initialize();
            weights[i].indicator = (ENUM_INDICATOR_TYPE)i;
            
            // Calcular peso base según expertise global
            weights[i].baseWeight = CalculateBaseWeight(i);
            
            // Aplicar bonus por contexto favorable
            weights[i].contextBonus = CalculateContextBonus(i, context);
            
            // Aplicar bonus por performance reciente
            weights[i].performanceBonus = CalculatePerformanceBonus(i);
            
            // Aplicar penalizaciones por errores
            weights[i].penaltyFactor = CalculatePenaltyFactor(i, context);
            
            // Calcular peso final
            weights[i].CalculateFinalWeight();
            
            // Determinar si está activo
            weights[i].isActive = (weights[i].finalWeight > 0.05);
        }
        
        // Normalizar pesos
        NormalizeWeights(weights);
        
        // Log de pesos si hay cambios significativos
        LogWeightChanges(weights);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Actualizar performance después de trade                         |
    //+------------------------------------------------------------------+
    void UpdatePerformance(int indicatorId, EnhancedMarketContext &context,
                          ENUM_VOTE_DIRECTION vote, bool won, double profit,
                          int bars, double mae, double mfe) {
        // Validar entrada
        if(indicatorId < 0 || indicatorId >= 8) return;

        // Obtener índices de contexto
        int ses = MathMin(4, (int)context.session);
        int vol = MathMin(4, (int)context.volatility);
        int dir = MathMin(4, (int)context.direction + 2); // Ajustar por valores negativos

        // Corrección de robustez: asegurar que el flag 'won' coincida con el signo del profit
        bool effectiveWon = won;
        if(profit > 0.0 && !won)
        {
            effectiveWon = true;
            //Log de autocorrección opcional:
            //Print("[VotingStats] Ajustando won->true por profit positivo: ", profit);
        }
        else if(profit < 0.0 && won)
        {
            effectiveWon = false;
            //Print("[VotingStats] Ajustando won->false por profit negativo: ", profit);
        }



        // Actualizar celda de performance (acceso directo sin puntero)
        m_performanceMatrix[indicatorId][ses][vol][dir].metrics.UpdateMetrics(vote, effectiveWon, profit, bars, mae, mfe);
        m_performanceMatrix[indicatorId][ses][vol][dir].sampleSize++;
        m_performanceMatrix[indicatorId][ses][vol][dir].lastUpdate = TimeCurrent();
        m_performanceMatrix[indicatorId][ses][vol][dir].UpdateExpertiseLevel();

        // Actualizar tracking horario
        MqlDateTime timeStruct;
        TimeToStruct(TimeCurrent(), timeStruct);
        int hour = timeStruct.hour;
        if(hour >= 0 && hour < 24) {
            if(effectiveWon) {
                m_performanceMatrix[indicatorId][ses][vol][dir].hourlyWinRate[hour] =
                    (m_performanceMatrix[indicatorId][ses][vol][dir].hourlyWinRate[hour] + 1.0) / 2.0;
            } else {
                m_performanceMatrix[indicatorId][ses][vol][dir].hourlyWinRate[hour] =
                    m_performanceMatrix[indicatorId][ses][vol][dir].hourlyWinRate[hour] / 2.0;
            }
        }

        // Actualizar especialización global
        m_specializations[indicatorId].globalMetrics.UpdateMetrics(vote, effectiveWon, profit, bars, mae, mfe);
        m_specializations[indicatorId].UpdateMarketTypeScores(context.regime, effectiveWon ? 1.0 : 0.0);
        m_specializations[indicatorId].UpdateTrustScore();

        // NUEVO: Actualizar peso dinámico basado en performance
        UpdateDynamicWeight(indicatorId);

        // NUEVO: Actualizar multiplicador de confianza por dirección
        UpdateConfidenceMultiplier(indicatorId, vote, effectiveWon);

        // Registrar error si fue pérdida significativa
        if(!effectiveWon && MathAbs(profit) > context.atr * 2) {
            RegisterErrorPattern(indicatorId, context, vote, MathAbs(profit));
        } else if(effectiveWon) {
            ClearErrorPattern(indicatorId, context);
        }

        // Actualizar estadísticas globales
        m_totalSystemTrades++;
        m_totalSystemProfit += profit;
        m_systemWinRate = ((m_systemWinRate * (m_totalSystemTrades - 1)) + (effectiveWon ? 1.0 : 0.0)) / m_totalSystemTrades;

        
        // Guardado periódico para evitar pérdida de datos ante cierres inesperados
        if(m_totalSystemTrades % 5 == 0)
            SaveHistoricalData();

// Guardar decisión en historial
        AddToDecisionHistory(context, vote, profit, effectiveWon);

        // NUEVO: Verificar si es momento de aprender (cada 10 trades del indicador)
        CheckAndLearnLesson(indicatorId);

        // Optimización periódica
        if(TimeCurrent() - m_lastOptimizationTime > 86400) { // Cada 24 horas
            OptimizeSystem();
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obtener recomendación para indicador específico                 |
    //+------------------------------------------------------------------+
    double GetIndicatorRecommendation(int indicatorId, EnhancedMarketContext &context, 
                                     ENUM_VOTE_DIRECTION direction) {
        if(indicatorId < 0 || indicatorId >= 8) return 0.5;
        
        // Obtener métricas para el contexto
        int ses = MathMin(4, (int)context.session);
        int vol = MathMin(4, (int)context.volatility);
        int dir = MathMin(4, (int)context.direction + 2);

        // Calcular score de recomendación (acceso directo sin puntero)
        double dirStrength = m_performanceMatrix[indicatorId][ses][vol][dir].metrics.GetDirectionalStrength(direction);
        double expertiseMultiplier = m_performanceMatrix[indicatorId][ses][vol][dir].GetExpertiseMultiplier();
        double trustScore = m_specializations[indicatorId].trustScore;

        // Score considerando el momentum actual
        double momentumBonus = (m_performanceMatrix[indicatorId][ses][vol][dir].metrics.performanceMomentum > 0) ? 1.1 : 0.9;
        
        // Score final
        double recommendation = dirStrength * expertiseMultiplier * trustScore * momentumBonus;
        
        // Si el indicador está en período de error, reducir recomendación
        if(HasRecentErrors(indicatorId, context)) {
            recommendation *= 0.7;
        }
        
        return MathMax(0.0, MathMin(1.0, recommendation));
    }
    
    //+------------------------------------------------------------------+
    //| Resolver conflictos entre indicadores                           |
    //+------------------------------------------------------------------+
    ENUM_VOTE_DIRECTION ResolveConflict(ENUM_VOTE_DIRECTION &votes[], double &confidences[], int count) {
        if(count <= 0) return VOTE_NEUTRAL;
        
        // Contar votos por dirección
        double buyScore = 0.0, sellScore = 0.0;
        int buyCount = 0, sellCount = 0;
        
        for(int i = 0; i < count; i++) {
            if(votes[i] == VOTE_BUY || votes[i] == VOTE_STRONG_BUY) {
                buyScore += confidences[i];
                buyCount++;
            } else if(votes[i] == VOTE_SELL || votes[i] == VOTE_STRONG_SELL) {
                sellScore += confidences[i];
                sellCount++;
            }
        }
        
        // Verificar correlaciones históricas en conflictos
        double conflictResolution = AnalyzeConflictHistory(buyCount, sellCount);
        
        // Ajustar scores basado en análisis de conflictos
        if(conflictResolution > 0) {
            buyScore *= (1 + conflictResolution);
        } else {
            sellScore *= (1 - conflictResolution);
        }
        
        // Decisión final
        double threshold = 0.55; // Requiere 55% de confianza para actuar
        double totalScore = buyScore + sellScore;
        
        if(totalScore > 0) {
            double buyRatio = buyScore / totalScore;
            double sellRatio = sellScore / totalScore;
            
            if(buyRatio > threshold) {
                return (buyRatio > 0.7) ? VOTE_STRONG_BUY : VOTE_BUY;
            } else if(sellRatio > threshold) {
                return (sellRatio > 0.7) ? VOTE_STRONG_SELL : VOTE_SELL;
            }
        }
        
        return VOTE_NEUTRAL;
    }
    
    //+------------------------------------------------------------------+
    //| Obtener estadísticas del sistema                                |
    //+------------------------------------------------------------------+
    string GetSystemStatistics() {
        string stats = "═══════════════════════════════════════════════\n";
        stats += "   SISTEMA DE VOTACIÓN ADAPTATIVO ENHANCED v5.0\n";
        stats += "═══════════════════════════════════════════════\n\n";

        stats += "📊 ESTADÍSTICAS GLOBALES\n";
        stats += StringFormat("├─ Total Trades: %d\n", m_totalSystemTrades);
        stats += StringFormat("├─ Win Rate Global: %.1f%%\n", m_systemWinRate * 100);
        stats += StringFormat("├─ Profit Total: %.2f\n", m_totalSystemProfit);
        stats += StringFormat("└─ Sharpe Ratio: %.2f\n\n", m_systemSharpe);
        
        stats += "🎯 RANKING DE INDICADORES\n";
        
        // Ordenar indicadores por trust score
        int indices[8];
        double scores[8];
        for(int i = 0; i < 8; i++) {
            indices[i] = i;
            scores[i] = m_specializations[i].trustScore;
        }
        
        // Bubble sort
        for(int i = 0; i < 7; i++) {
            for(int j = 0; j < 7 - i; j++) {
                if(scores[j] < scores[j + 1]) {
                    double tempScore = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = tempScore;
                    
                    int tempIdx = indices[j];
                    indices[j] = indices[j + 1];
                    indices[j + 1] = tempIdx;
                }
            }
        }
        
        // Mostrar ranking
        for(int i = 0; i < 8; i++) {
            int idx = indices[i];

            string medal = "";
            if(i == 0) medal = "🥇";
            else if(i == 1) medal = "🥈";
            else if(i == 2) medal = "🥉";
            else medal = StringFormat("%d.", i + 1);

            stats += StringFormat("%s %s\n", medal, m_specializations[idx].indicatorName);
            stats += StringFormat("   ├─ Trust: %.1f%% | ", m_specializations[idx].trustScore * 100);
            stats += StringFormat("Trades: %d | ", m_specializations[idx].globalMetrics.GetTotalTrades());
            stats += StringFormat("Win Rate: %.1f%%\n", m_specializations[idx].globalMetrics.GetTotalWinRate() * 100);
            stats += StringFormat("   ├─ BUY: %d trades (%.1f%%) | ", 
                m_specializations[idx].globalMetrics.buyTrades,
                m_specializations[idx].globalMetrics.buyWinRate * 100);
            stats += StringFormat("SELL: %d trades (%.1f%%)\n",
                m_specializations[idx].globalMetrics.sellTrades,
                m_specializations[idx].globalMetrics.sellWinRate * 100);
            stats += StringFormat("   └─ Momentum: %+.2f | ", m_specializations[idx].globalMetrics.performanceMomentum);
            stats += StringFormat("Confidence: %.1f%% | ", m_specializations[idx].globalMetrics.confidenceScore * 100);
            stats += StringFormat("PF: %.2f\n\n", m_specializations[idx].globalMetrics.GetTotalProfitFactor());
        }
        
        // Contexto actual
        stats += "🌍 CONTEXTO DE MERCADO ACTUAL\n";
        stats += StringFormat("├─ Sesión: %s\n", GetSessionName(m_currentContext.session));
        stats += StringFormat("├─ Volatilidad: %s (%.2f)\n", 
            GetVolatilityName(m_currentContext.volatility), m_currentContext.atr);
        stats += StringFormat("├─ Dirección: %s\n", GetDirectionName(m_currentContext.direction));
        stats += StringFormat("├─ Régimen: %s\n", GetRegimeName(m_currentContext.regime));
        stats += StringFormat("└─ Complejidad: %.1f%%\n\n", m_currentContext.contextComplexity * 100);
        
        // Última optimización
        int hoursAgo = (int)((TimeCurrent() - m_lastOptimizationTime) / 3600);
        stats += StringFormat("⚙️ Última Optimización: hace %d horas\n", hoursAgo);
        
        int barsToReset = m_adaptivePeriodBars - (Bars(_Symbol, PERIOD_CURRENT) % m_adaptivePeriodBars);
        stats += StringFormat("🔄 Próximo Reset Adaptativo: en %d barras\n", barsToReset);
        
        stats += "═══════════════════════════════════════════════\n";
        
        return stats;
    }
    
    //+------------------------------------------------------------------+
    //| Generar reporte compacto de indicadores (solo con trades > 0)   |
    //+------------------------------------------------------------------+
    string GetCompactIndicatorReport() {
        string report = "\n";
        report += "╔══════════════════════════════════════════════════════╗\n";
        report += "║         REPORTE HORARIO DE PERFORMANCE               ║\n";
        report += "╚══════════════════════════════════════════════════════╝\n\n";
        
        // Obtener nivel de expertise en texto
        string expertiseNames[8] = {"None", "Learning", "Novice", "Competent", "Proficient", "Expert", "Master", "Grandmaster"};
        
        for(int i = 0; i < 8; i++) {
            int totalTrades = m_specializations[i].globalMetrics.GetTotalTrades();
            
            // Solo mostrar indicadores con trades > 0
            if(totalTrades == 0) continue;
            
            int totalWins = m_specializations[i].globalMetrics.GetTotalWins();
            double winRate = m_specializations[i].globalMetrics.GetTotalWinRate();
            double totalProfit = m_specializations[i].globalMetrics.GetTotalProfit();
            double profitFactor = m_specializations[i].globalMetrics.GetTotalProfitFactor();
            
            // Determinar nivel de expertise basado en trades totales
            ENUM_EXPERTISE_LEVEL expertise = EXPERTISE_LEARNING;
            if(totalTrades >= 20) expertise = EXPERTISE_NOVICE;
            if(totalTrades >= 50 && winRate > 0.52) expertise = EXPERTISE_COMPETENT;
            if(totalTrades >= 100 && winRate > 0.58) expertise = EXPERTISE_PROFICIENT;
            if(totalTrades >= 200 && winRate > 0.62) expertise = EXPERTISE_EXPERT;
            if(totalTrades >= 500 && winRate > 0.68) expertise = EXPERTISE_MASTER;
            if(totalTrades >= 1000 && winRate > 0.72) expertise = EXPERTISE_GRANDMASTER;
            
            report += StringFormat("▶ %s [%s]\n", 
                m_specializations[i].indicatorName,
                expertiseNames[expertise]);
            report += StringFormat("╟─ Trades: %d | Wins: %d\n", totalTrades, totalWins);
            report += StringFormat("╟─ Win Rate: %.1f%%\n", winRate * 100);
            report += StringFormat("╟─ Peso: x%.2f | ", m_specializations[i].adaptationRate);
            report += StringFormat("Veto: %s\n", (m_specializations[i].trustScore < 0.3) ? "SÍ" : "NO");
            report += StringFormat("╟─ P&L: %.2f | ", totalProfit);
            report += StringFormat("PF: %.2f\n", profitFactor);
            report += "╚════════════════════════════════════════════════════\n\n";
        }
        
        // Estadísticas globales
        report += "═══ ESTADÍSTICAS GLOBALES ═══\n";
        report += StringFormat("▶ Ciclos completados: %d\n", m_totalSystemTrades);
        
        // Calcular trades del día (últimas 24 horas)
        datetime today = TimeCurrent() - 86400;
        int tradesToday = 0;
        for(int i = 0; i < 8; i++) {
            // Esta es una aproximación, idealmente necesitaríamos tracking por fecha
            tradesToday += m_specializations[i].globalMetrics.GetTotalTrades();
        }
        
        report += StringFormat("▶ Trades hoy: %d\n", tradesToday);
        report += StringFormat("▶ Win Rate global: %.1f%%\n", m_systemWinRate * 100);
        
        // Win rate de consenso (aproximación)
        double consensusWR = 0.0;
        int consensusTrades = 0;
        for(int i = 0; i < 8; i++) {
            int trades = m_specializations[i].globalMetrics.GetTotalTrades();
            if(trades > 0) {
                consensusWR += m_specializations[i].globalMetrics.GetTotalWinRate() * trades;
                consensusTrades += trades;
            }
        }
        if(consensusTrades > 0) consensusWR /= consensusTrades;
        
        report += StringFormat("▶ Win Rate consenso: %.1f%%\n\n", consensusWR * 100);
        
        // Información del régimen actual
        report += StringFormat("📈 RÉGIMEN: %s\n", GetRegimeName(m_currentContext.regime));
        report += StringFormat("    Trades en régimen: %d\n", 0); // TODO: Implementar tracking por régimen
        report += StringFormat("    P&L en régimen: %.2f\n\n", 0.0); // TODO: Implementar tracking por régimen
        
        report += "╚══════════════════════════════════════════════════════╝\n";
        
        return report;
    }
    
private:
    //+------------------------------------------------------------------+
    //| Calcular peso base del indicador                                |
    //+------------------------------------------------------------------+
    double CalculateBaseWeight(int indicatorId) {
        // Usar adaptationRate actualizado dinámicamente (rango 0.5 - 2.0)
        // Este se actualiza en UpdateDynamicWeight() basado en WinRate, ProfitFactor y Momentum
        double dynamicWeight = m_specializations[indicatorId].adaptationRate;

        // Bonus por experiencia (hasta +0.2)
        int totalTrades = m_specializations[indicatorId].globalMetrics.GetTotalTrades();
        double experienceBonus = 0.0;
        if(totalTrades > 100) experienceBonus += 0.1;
        if(totalTrades > 500) experienceBonus += 0.1;

        // Peso final = adaptationRate + bonus experiencia
        double finalWeight = dynamicWeight + experienceBonus;

        // Limitar al rango 0.5 - 2.5
        return MathMax(0.5, MathMin(2.5, finalWeight));
    }
    
    //+------------------------------------------------------------------+
    //| Calcular bonus por contexto favorable                           |
    //+------------------------------------------------------------------+
    double CalculateContextBonus(int indicatorId, EnhancedMarketContext &context) {
        // Verificar si es experto en este contexto
        if(m_specializations[indicatorId].IsExpertIn(context.contextID)) {
            return 0.3; // 30% bonus si es experto
        }
        
        // Bonus parcial por tipo de mercado
        double marketBonus = 0.0;
        switch(context.regime) {
            case REGIME_TRENDING_UP:
            case REGIME_TRENDING_DOWN:
                marketBonus = (m_specializations[indicatorId].trendingMarketScore - 0.5) * 0.4;
                break;
            case REGIME_RANGING:
                marketBonus = (m_specializations[indicatorId].rangingMarketScore - 0.5) * 0.4;
                break;
            case REGIME_VOLATILE:
            case REGIME_CRISIS:
                marketBonus = (m_specializations[indicatorId].volatileMarketScore - 0.5) * 0.4;
                break;
        }
        
        return MathMax(-0.2, MathMin(0.3, marketBonus));
    }
    
    //+------------------------------------------------------------------+
    //| Calcular bonus por performance reciente                         |
    //+------------------------------------------------------------------+
    double CalculatePerformanceBonus(int indicatorId) {
        // Usar confianza ajustada (rango 0.1 - 1.0)
        double confidence = m_specializations[indicatorId].globalMetrics.confidenceScore;

        // Bonus por momentum positivo (acceso directo sin puntero)
        double momentumBonus = 0.0;
        if(m_specializations[indicatorId].globalMetrics.performanceMomentum > 0) {
            momentumBonus = m_specializations[indicatorId].globalMetrics.performanceMomentum * 0.2;
        } else {
            // Penalización por momentum negativo (más suave)
            momentumBonus = m_specializations[indicatorId].globalMetrics.performanceMomentum * 0.1;
        }

        // Bonus combinado: confianza + momentum
        // Rango total: -0.2 a +0.5
        double totalBonus = ((confidence - 0.5) * 0.4) + momentumBonus;

        return MathMax(-0.3, MathMin(0.5, totalBonus));
    }
    
    //+------------------------------------------------------------------+
    //| Calcular factor de penalización                                 |
    //+------------------------------------------------------------------+
    double CalculatePenaltyFactor(int indicatorId, EnhancedMarketContext &context) {
        double penalty = 1.0;
        
        // Buscar patrones de error recientes
        for(int i = 0; i < ArraySize(m_errorPatterns); i++) {
            if(m_errorPatterns[i].indicator == indicatorId) {
                // Si el error fue en contexto similar
                if(ContextsAreSimilar(m_errorPatterns[i], context)) {
                    penalty = MathMin(penalty, m_errorPatterns[i].penaltyFactor);
                }
            }
        }
        
        return penalty;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar si hay errores recientes                              |
    //+------------------------------------------------------------------+
    bool HasRecentErrors(int indicatorId, EnhancedMarketContext &context) {
        datetime threshold = TimeCurrent() - 3600 * 24; // Últimas 24 horas
        
        for(int i = 0; i < ArraySize(m_errorPatterns); i++) {
            if(m_errorPatterns[i].indicator == indicatorId && 
               m_errorPatterns[i].lastError > threshold) {
                if(ContextsAreSimilar(m_errorPatterns[i], context)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar si contextos son similares                            |
    //+------------------------------------------------------------------+
    bool ContextsAreSimilar(ContextualErrorPattern &pattern, EnhancedMarketContext &context) {
        return (pattern.session == context.session &&
                pattern.volatility == context.volatility &&
                MathAbs(pattern.marketDir - context.direction) <= 1);
    }
    
    //+------------------------------------------------------------------+
    //| Registrar patrón de error                                       |
    //+------------------------------------------------------------------+
    void RegisterErrorPattern(int indicatorId, EnhancedMarketContext &context, 
                             ENUM_VOTE_DIRECTION vote, double lossSize) {
        // Buscar patrón existente
        int patternIndex = -1;
        for(int i = 0; i < ArraySize(m_errorPatterns); i++) {
            if(m_errorPatterns[i].indicator == indicatorId &&
               m_errorPatterns[i].session == context.session &&
               m_errorPatterns[i].volatility == context.volatility &&
               m_errorPatterns[i].marketDir == context.direction &&
               m_errorPatterns[i].voteDir == vote) {
                patternIndex = i;
                break;
            }
        }
        
        // Crear nuevo patrón si no existe
        if(patternIndex == -1) {
            patternIndex = ArraySize(m_errorPatterns);
            ArrayResize(m_errorPatterns, patternIndex + 1);
            m_errorPatterns[patternIndex].Initialize();
            m_errorPatterns[patternIndex].indicator = (ENUM_INDICATOR_TYPE)indicatorId;
            m_errorPatterns[patternIndex].session = context.session;
            m_errorPatterns[patternIndex].volatility = context.volatility;
            m_errorPatterns[patternIndex].marketDir = context.direction;
            m_errorPatterns[patternIndex].voteDir = vote;
        }
        
        // Actualizar patrón
        m_errorPatterns[patternIndex].RegisterError(lossSize);
    }
    
    //+------------------------------------------------------------------+
    //| Limpiar patrón de error después de éxito                       |
    //+------------------------------------------------------------------+
    void ClearErrorPattern(int indicatorId, EnhancedMarketContext &context) {
        for(int i = 0; i < ArraySize(m_errorPatterns); i++) {
            if(m_errorPatterns[i].indicator == indicatorId &&
               ContextsAreSimilar(m_errorPatterns[i], context)) {
                m_errorPatterns[i].RegisterSuccess();
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analizar historial de conflictos                                |
    //+------------------------------------------------------------------+
    double AnalyzeConflictHistory(int buyCount, int sellCount) {
        if(buyCount == 0 || sellCount == 0) return 0.0;
        
        // Buscar correlación relevante
        double totalConflictWinRate = 0.0;
        int relevantConflicts = 0;
        
        for(int i = 0; i < 28; i++) {
            if(m_correlations[i].conflictCount > 10) {
                totalConflictWinRate += m_correlations[i].conflictWinRate;
                relevantConflicts++;
            }
        }
        
        if(relevantConflicts > 0) {
            double avgConflictWinRate = totalConflictWinRate / relevantConflicts;
            // Si los conflictos históricamente favorecen una dirección
            return (avgConflictWinRate - 0.5) * 0.3;
        }
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar y ejecutar reseteo adaptativo                         |
    //+------------------------------------------------------------------+
    void CheckAdaptiveReset() {
        // Calcular período adaptativo basado en volatilidad
        double volatilityFactor = 1.0 + (m_currentContext.volatilityChange * 0.5);
        int adaptedPeriod = (int)(m_adaptivePeriodBars / volatilityFactor);
        
        // Reseteo más frecuente en mercados volátiles
        if(m_currentContext.volatility >= VOL_HIGH) {
            adaptedPeriod = (int)(adaptedPeriod * 0.7);
        }
        
        // Verificar si es tiempo de reseteo
        if(Bars(_Symbol, PERIOD_CURRENT) % adaptedPeriod == 0) {
            ApplyAdaptiveDecay();
            m_lastResetTime = TimeCurrent();
        }
    }
    
    //+------------------------------------------------------------------+
    //| Aplicar decay adaptativo a las métricas                         |
    //+------------------------------------------------------------------+
    void ApplyAdaptiveDecay() {
        double decayFactor = 0.95; // Factor base
        
        // Ajustar decay según complejidad del mercado
        if(m_currentContext.contextComplexity > 0.7) {
            decayFactor = 0.90; // Decay más agresivo en mercados complejos
        } else if(m_currentContext.contextComplexity < 0.3) {
            decayFactor = 0.98; // Decay más suave en mercados simples
        }
        
        // Aplicar decay a todas las celdas
        for(int ind = 0; ind < 8; ind++) {
            for(int ses = 0; ses < 5; ses++) {
                for(int vol = 0; vol < 5; vol++) {
                    for(int dir = 0; dir < 5; dir++) {
                        // Solo aplicar decay a celdas con datos antiguos (acceso directo sin puntero)
                        if(TimeCurrent() - m_performanceMatrix[ind][ses][vol][dir].lastUpdate > 86400 * 7) { // Más de 7 días
                            m_performanceMatrix[ind][ses][vol][dir].metrics.confidenceScore *= decayFactor;
                            m_performanceMatrix[ind][ses][vol][dir].metrics.recentWinRate =
                                (m_performanceMatrix[ind][ses][vol][dir].metrics.recentWinRate + 0.5) / 2;
                        }
                    }
                }
            }
        }
        
        Print("🔄 Decay adaptativo aplicado con factor: ", decayFactor);
    }
    
    //+------------------------------------------------------------------+
    //| Normalizar pesos para que sumen 1.0                             |
    //+------------------------------------------------------------------+
    void NormalizeWeights(EnhancedDynamicWeight &weights[]) {
        double sum = 0.0;
        int activeCount = 0;
        
        for(int i = 0; i < 8; i++) {
            if(weights[i].isActive) {
                sum += weights[i].finalWeight;
                activeCount++;
            }
        }
        
        if(sum > 0 && activeCount > 0) {
            for(int i = 0; i < 8; i++) {
                if(weights[i].isActive) {
                    weights[i].finalWeight = weights[i].finalWeight / sum;
                } else {
                    weights[i].finalWeight = 0.0;
                }
            }
        } else {
            // Distribuir uniformemente si no hay activos
            for(int i = 0; i < 8; i++) {
                weights[i].finalWeight = 0.125;
                weights[i].isActive = true;
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Optimización periódica del sistema                              |
    //+------------------------------------------------------------------+
    void OptimizeSystem() {
        // Recalcular rankings globales
        CalculateGlobalRankings();
        
        // Ajustar velocidades de aprendizaje
        AdjustLearningRates();
        
        // Limpiar patrones de error obsoletos
        CleanObsoleteErrorPatterns();
        
        // Actualizar correlaciones
        UpdateIndicatorCorrelations();
        
        m_lastOptimizationTime = TimeCurrent();
        
        Print("⚙️ Optimización del sistema completada");
    }
    
    //+------------------------------------------------------------------+
    //| Calcular rankings globales de indicadores                       |
    //+------------------------------------------------------------------+
    void CalculateGlobalRankings() {
        double scores[8];
        int indices[8];
        
        for(int i = 0; i < 8; i++) {
            indices[i] = i;
            scores[i] = m_specializations[i].trustScore * 
                       m_specializations[i].globalMetrics.confidenceScore;
        }
        
        // Ordenar por score
        for(int i = 0; i < 7; i++) {
            for(int j = 0; j < 7 - i; j++) {
                if(scores[j] < scores[j + 1]) {
                    double tempScore = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = tempScore;
                    
                    int tempIdx = indices[j];
                    indices[j] = indices[j + 1];
                    indices[j + 1] = tempIdx;
                }
            }
        }
        
        // Asignar rankings
        for(int i = 0; i < 8; i++) {
            m_specializations[indices[i]].globalRank = i + 1;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Ajustar velocidades de aprendizaje                              |
    //+------------------------------------------------------------------+
    void AdjustLearningRates() {
        for(int i = 0; i < 8; i++) {
            double momentum = m_specializations[i].globalMetrics.performanceMomentum;
            
            // Acelerar aprendizaje si está mejorando
            if(momentum > 0.3) {
                m_specializations[i].learningSpeed = LEARN_FAST;
            } else if(momentum > 0.1) {
                m_specializations[i].learningSpeed = LEARN_NORMAL;
            } else if(momentum < -0.3) {
                m_specializations[i].learningSpeed = LEARN_ULTRA_FAST; // Necesita adaptarse rápido
            } else {
                m_specializations[i].learningSpeed = LEARN_NORMAL;
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Limpiar patrones de error obsoletos                             |
    //+------------------------------------------------------------------+
    void CleanObsoleteErrorPatterns() {
        datetime threshold = TimeCurrent() - 86400 * 30; // 30 días
        
        int validPatterns = 0;
        for(int i = 0; i < ArraySize(m_errorPatterns); i++) {
            if(m_errorPatterns[i].lastError > threshold || 
               m_errorPatterns[i].isRecovering) {
                // Mantener patrón válido
                if(i != validPatterns) {
                    m_errorPatterns[validPatterns] = m_errorPatterns[i];
                }
                validPatterns++;
            }
        }
        
        if(validPatterns < ArraySize(m_errorPatterns)) {
            ArrayResize(m_errorPatterns, validPatterns);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Actualizar correlaciones entre indicadores                      |
    //+------------------------------------------------------------------+
    void UpdateIndicatorCorrelations() {
        // Este método se llamaría después de cada votación
        // para actualizar las correlaciones basadas en los votos
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Actualizar peso dinámico del indicador                   |
    //+------------------------------------------------------------------+
    void UpdateDynamicWeight(int indicatorId) {
        if(indicatorId < 0 || indicatorId >= 8) return;

        // Calcular nuevo peso base según WinRate y ProfitFactor
        double avgWinRate = (m_specializations[indicatorId].globalMetrics.buyWinRate +
                            m_specializations[indicatorId].globalMetrics.sellWinRate) / 2;
        double avgPF = (m_specializations[indicatorId].globalMetrics.buyProfitFactor +
                       m_specializations[indicatorId].globalMetrics.sellProfitFactor) / 2;
        double momentum = m_specializations[indicatorId].globalMetrics.performanceMomentum;

        // Peso dinámico: 0.5 - 2.0
        double newWeight = 1.0; // Base

        // Ajuste por WinRate (versión agresiva)
        if(avgWinRate > 0.5) {
            // Si el indicador es consistentemente bueno, lo premiamos más fuerte
            newWeight += (avgWinRate - 0.5) * 0.8; 
        } else {
            // Si WR < 40%, penalización casi total: indicador prácticamente silenciado
            if(avgWinRate < 0.40)
                newWeight = 0.01;
            else
                // Penalización doble en la zona 40% - 50%
                newWeight -= (0.5 - avgWinRate) * 2.0;
        }

        // Ajuste por ProfitFactor (±0.3)
        if(avgPF > 1.0) {
            newWeight += MathMin(0.3, (avgPF - 1.0) * 0.15);
        } else {
            newWeight -= MathMin(0.3, (1.0 - avgPF) * 0.15);
        }

        // Ajuste por momentum (±0.2)
        newWeight += momentum * 0.2;

        // Limitar rango 0.5 - 2.0
        newWeight = MathMax(0.5, MathMin(2.0, newWeight));

        // Actualizar (aplicar suavizado)
        m_specializations[indicatorId].adaptationRate =
            (m_specializations[indicatorId].adaptationRate * 0.8) + (newWeight * 0.2);
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Actualizar multiplicador de confianza por dirección      |
    //+------------------------------------------------------------------+
    void UpdateConfidenceMultiplier(int indicatorId, ENUM_VOTE_DIRECTION vote, bool won) {
        if(indicatorId < 0 || indicatorId >= 8) return;

        // Incremento/decremento basado en resultado
        double delta = won ? 0.10 : -0.08; // +10% si gana, -8% si pierde

        // Aplicar a la métrica de dirección correspondiente
        if(vote == VOTE_BUY || vote == VOTE_STRONG_BUY) {
            // Ajustar confianza en BUY
            double currentConf = m_specializations[indicatorId].globalMetrics.buyWinRate;
            double newConf = MathMax(0.3, MathMin(2.5, currentConf * (1.0 + delta)));

            // Actualizar con suavizado
            m_specializations[indicatorId].globalMetrics.confidenceScore =
                (m_specializations[indicatorId].globalMetrics.confidenceScore * 0.9) + (newConf * 0.1);

        } else if(vote == VOTE_SELL || vote == VOTE_STRONG_SELL) {
            // Ajustar confianza en SELL
            double currentConf = m_specializations[indicatorId].globalMetrics.sellWinRate;
            double newConf = MathMax(0.3, MathMin(2.5, currentConf * (1.0 + delta)));

            // Actualizar con suavizado
            m_specializations[indicatorId].globalMetrics.confidenceScore =
                (m_specializations[indicatorId].globalMetrics.confidenceScore * 0.9) + (newConf * 0.1);
        }
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Verificar y aprender cada 10 trades                      |
    //+------------------------------------------------------------------+
    void CheckAndLearnLesson(int indicatorId) {
        if(indicatorId < 0 || indicatorId >= 8) return;

        // Array estático para rastrear la última lección aprendida por cada indicador
        static int lastLessonNumber[8] = {0, 0, 0, 0, 0, 0, 0, 0};

        // Obtener total de trades del indicador
        int totalTrades = m_specializations[indicatorId].globalMetrics.buyTrades +
                         m_specializations[indicatorId].globalMetrics.sellTrades;

        // Calcular número de lección actual (cada 10 trades)
        int currentLessonNumber = totalTrades / 10;

        // Aprender solo si hay suficientes trades Y la lección es nueva
        if(totalTrades >= 10 && currentLessonNumber > lastLessonNumber[indicatorId]) {
            lastLessonNumber[indicatorId] = currentLessonNumber;

            Print("📚 LECCIÓN #", currentLessonNumber, " - Analizando indicador: ",
                  m_specializations[indicatorId].indicatorName,
                  " (", totalTrades, " trades totales)");

            AnalyzeAndAdapt(indicatorId);
        }
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Analizar y adaptar basado en aprendizaje                 |
    //+------------------------------------------------------------------+
    void AnalyzeAndAdapt(int indicatorId) {
        if(indicatorId < 0 || indicatorId >= 8) return;

        string indicatorName = m_specializations[indicatorId].indicatorName;
        int totalTrades = m_specializations[indicatorId].globalMetrics.buyTrades +
                         m_specializations[indicatorId].globalMetrics.sellTrades;

        Print("┌─────────────────────────────────────────────────────────────");
        Print("│ 🎓 ANÁLISIS Y ADAPTACIÓN - ", indicatorName);
        Print("│ Total Trades: ", totalTrades);
        Print("├─────────────────────────────────────────────────────────────");

        // 1. Analizar mejor sesión
        ENUM_TRADING_SESSION bestSession = SESSION_ASIA;
        double bestSessionWR = 0.0;

        for(int ses = 0; ses < 5; ses++) {
            double sessionWR = CalculateSessionWinRate(indicatorId, (ENUM_TRADING_SESSION)ses);
            if(sessionWR > bestSessionWR) {
                bestSessionWR = sessionWR;
                bestSession = (ENUM_TRADING_SESSION)ses;
            }
        }

        Print("│ ✅ Mejor Sesión: ", GetSessionName(bestSession),
              " (WR: ", DoubleToString(bestSessionWR * 100, 1), "%)");

        // 2. Analizar mejor volatilidad
        ENUM_VOLATILITY_LEVEL bestVol = VOL_MEDIUM;
        double bestVolWR = 0.0;

        for(int vol = 0; vol < 5; vol++) {
            double volWR = CalculateVolatilityWinRate(indicatorId, (ENUM_VOLATILITY_LEVEL)vol);
            if(volWR > bestVolWR) {
                bestVolWR = volWR;
                bestVol = (ENUM_VOLATILITY_LEVEL)vol;
            }
        }

        Print("│ ✅ Mejor Volatilidad: ", GetVolatilityName(bestVol),
              " (WR: ", DoubleToString(bestVolWR * 100, 1), "%)");

        // 3. Analizar especialización direccional
        double buyWR = m_specializations[indicatorId].globalMetrics.buyWinRate;
        double sellWR = m_specializations[indicatorId].globalMetrics.sellWinRate;

        string specialization = "Balanceado";
        if(buyWR > sellWR + 0.1) {
            specialization = "BUY";
        } else if(sellWR > buyWR + 0.1) {
            specialization = "SELL";
        }

        Print("│ ✅ Especialización: ", specialization,
              " (BUY: ", DoubleToString(buyWR * 100, 1), "% | SELL: ",
              DoubleToString(sellWR * 100, 1), "%)");

        // 4. Calcular nivel de expertise basado en métricas globales
        ENUM_EXPERTISE_LEVEL expertise = EXPERTISE_NONE;
        double avgWinRate = (buyWR + sellWR) / 2;
        double avgPF = (m_specializations[indicatorId].globalMetrics.buyProfitFactor +
                       m_specializations[indicatorId].globalMetrics.sellProfitFactor) / 2;

        // Determinar expertise basado en trades y performance
        if(totalTrades < 20) {
            expertise = EXPERTISE_LEARNING;
        } else if(totalTrades < 50) {
            expertise = (avgWinRate > 0.52) ? EXPERTISE_NOVICE : EXPERTISE_LEARNING;
        } else if(totalTrades < 100) {
            if(avgWinRate > 0.58 && avgPF > 1.3) expertise = EXPERTISE_COMPETENT;
            else expertise = EXPERTISE_NOVICE;
        } else if(totalTrades < 200) {
            if(avgWinRate > 0.62 && avgPF > 1.5) expertise = EXPERTISE_PROFICIENT;
            else expertise = EXPERTISE_COMPETENT;
        } else if(totalTrades < 500) {
            if(avgWinRate > 0.65 && avgPF > 1.8) expertise = EXPERTISE_EXPERT;
            else expertise = EXPERTISE_PROFICIENT;
        } else if(totalTrades < 1000) {
            if(avgWinRate > 0.68 && avgPF > 2.0) expertise = EXPERTISE_MASTER;
            else expertise = EXPERTISE_EXPERT;
        } else {
            if(avgWinRate > 0.72 && avgPF > 2.5) expertise = EXPERTISE_GRANDMASTER;
            else expertise = EXPERTISE_MASTER;
        }

        Print("│ 🏆 Nivel de Expertise: ", GetExpertiseName(expertise));

        // 5. Generar insight completo
        string insight = GenerateInsight(indicatorName, totalTrades, bestSession, bestSessionWR,
                                        bestVol, bestVolWR, specialization, buyWR, sellWR);

        Print("│");
        Print("│ 💡 INSIGHT:");
        Print("│ ", insight);
        Print("└─────────────────────────────────────────────────────────────");

        // 6. Adaptar pesos si es necesario
        AdaptWeightsForContext(indicatorId, bestSession, bestVol);
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Generar insight de aprendizaje                           |
    //+------------------------------------------------------------------+
    string GenerateInsight(string name, int trades, ENUM_TRADING_SESSION bestSession,
                          double sessionWR, ENUM_VOLATILITY_LEVEL bestVol, double volWR,
                          string specialization, double buyWR, double sellWR) {
        string insight = name + " (" + IntegerToString(trades) + " trades): ";

        // Insight sobre sesión
        if(sessionWR > 0.65) {
            insight += "Excelente en " + GetSessionName(bestSession) + " (" +
                      DoubleToString(sessionWR * 100, 0) + "%). ";
        } else if(sessionWR > 0.55) {
            insight += "Mejor en " + GetSessionName(bestSession) + " (" +
                      DoubleToString(sessionWR * 100, 0) + "%). ";
        }

        // Insight sobre volatilidad
        if(volWR > 0.65) {
            insight += "Domina en volatilidad " + GetVolatilityName(bestVol) + ". ";
        }

        // Insight sobre dirección
        if(specialization != "Balanceado") {
            insight += "Especializado en " + specialization + ". ";
        }

        // Recomendación
        if(sessionWR > 0.70 || volWR > 0.70) {
            insight += "¡Seguir explotando estas condiciones!";
        } else if(sessionWR < 0.45 && volWR < 0.45) {
            insight += "Necesita más datos para mejorar.";
        }

        return insight;
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Adaptar pesos para contextos favorables                  |
    //+------------------------------------------------------------------+
    void AdaptWeightsForContext(int indicatorId, ENUM_TRADING_SESSION bestSession,
                               ENUM_VOLATILITY_LEVEL bestVol) {
        if(indicatorId < 0 || indicatorId >= 8) return;

        // Aumentar peso base del indicador en 5% cuando identifica su mejor contexto
        // Esto ayuda a que el indicador tenga más influencia en sus condiciones óptimas
        double currentWeight = m_specializations[indicatorId].adaptationRate;
        double newWeight = MathMin(2.0, currentWeight * 1.05);

        // Solo actualizar si el nuevo peso es mejor
        if(newWeight > currentWeight) {
            m_specializations[indicatorId].adaptationRate = newWeight;

            Print("│ ⚙️ Peso adaptado: ", m_specializations[indicatorId].indicatorName,
                  " de ", DoubleToString(currentWeight, 3), " a ", DoubleToString(newWeight, 3));
        }
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Calcular WinRate por sesión                              |
    //+------------------------------------------------------------------+
    double CalculateSessionWinRate(int indicatorId, ENUM_TRADING_SESSION session) {
        int totalWins = 0;
        int totalTrades = 0;

        int ses = (int)session;

        for(int vol = 0; vol < 5; vol++) {
            for(int dir = 0; dir < 5; dir++) {
                totalWins += (m_performanceMatrix[indicatorId][ses][vol][dir].metrics.buyWins +
                             m_performanceMatrix[indicatorId][ses][vol][dir].metrics.sellWins);
                totalTrades += (m_performanceMatrix[indicatorId][ses][vol][dir].metrics.buyTrades +
                               m_performanceMatrix[indicatorId][ses][vol][dir].metrics.sellTrades);
            }
        }

        return (totalTrades > 0) ? (double)totalWins / totalTrades : 0.5;
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Calcular WinRate por volatilidad                         |
    //+------------------------------------------------------------------+
    double CalculateVolatilityWinRate(int indicatorId, ENUM_VOLATILITY_LEVEL volatility) {
        int totalWins = 0;
        int totalTrades = 0;

        int vol = (int)volatility;

        for(int ses = 0; ses < 5; ses++) {
            for(int dir = 0; dir < 5; dir++) {
                totalWins += (m_performanceMatrix[indicatorId][ses][vol][dir].metrics.buyWins +
                             m_performanceMatrix[indicatorId][ses][vol][dir].metrics.sellWins);
                totalTrades += (m_performanceMatrix[indicatorId][ses][vol][dir].metrics.buyTrades +
                               m_performanceMatrix[indicatorId][ses][vol][dir].metrics.sellTrades);
            }
        }

        return (totalTrades > 0) ? (double)totalWins / totalTrades : 0.5;
    }

    //+------------------------------------------------------------------+
    //| NUEVO: Obtener nombre de nivel de expertise                     |
    //+------------------------------------------------------------------+
    string GetExpertiseName(ENUM_EXPERTISE_LEVEL level) {
        switch(level) {
            case EXPERTISE_GRANDMASTER: return "GrandMaster";
            case EXPERTISE_MASTER: return "Master";
            case EXPERTISE_EXPERT: return "Expert";
            case EXPERTISE_PROFICIENT: return "Proficient";
            case EXPERTISE_COMPETENT: return "Competent";
            case EXPERTISE_NOVICE: return "Novice";
            case EXPERTISE_LEARNING: return "Learning";
            default: return "None";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Agregar decisión al historial                                   |
    //+------------------------------------------------------------------+
    void AddToDecisionHistory(EnhancedMarketContext &context, 
                             ENUM_VOTE_DIRECTION decision, 
                             double result, bool wasCorrect) {
        int size = ArraySize(m_decisionHistory);
        ArrayResize(m_decisionHistory, size + 1);
        
        m_decisionHistory[size].timestamp = TimeCurrent();
        m_decisionHistory[size].contextID = context.contextID;
        m_decisionHistory[size].decision = decision;
        m_decisionHistory[size].confidence = context.regimeConfidence;
        m_decisionHistory[size].reasoning = "";
        m_decisionHistory[size].result = result;
        m_decisionHistory[size].wasCorrect = wasCorrect;
        
        // Mantener solo últimas 1000 decisiones
        if(ArraySize(m_decisionHistory) > 1000) {
            ArrayRemove(m_decisionHistory, 0, 1);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Log de cambios significativos en pesos                          |
    //+------------------------------------------------------------------+
    void LogWeightChanges(EnhancedDynamicWeight &weights[]) {
        static double lastWeights[8] = {0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125};
        bool significantChange = false;
        
        for(int i = 0; i < 8; i++) {
            if(MathAbs(weights[i].finalWeight - lastWeights[i]) > 0.05) {
                significantChange = true;
                break;
            }
        }
        
        if(significantChange) {
            Print("📊 Cambio significativo en pesos detectado:");
            for(int i = 0; i < 8; i++) {
                if(weights[i].isActive) {
                    Print("   ", m_specializations[i].indicatorName, 
                          ": ", DoubleToString(lastWeights[i], 3), 
                          " → ", DoubleToString(weights[i].finalWeight, 3),
                          " | ", weights[i].reasoning);
                }
                lastWeights[i] = weights[i].finalWeight;
            }
        }
    }

public:
    //+------------------------------------------------------------------+
    //| Guardar datos históricos                                        |
    //+------------------------------------------------------------------+
    void SaveHistoricalData() {
        string filename = "VotingSystem_" + _Symbol + "_Enhanced.bin";
        int handle = FileOpen(filename, FILE_WRITE|FILE_BIN);
        
        if(handle == INVALID_HANDLE) {
            Print("⚠ No se pudieron guardar datos históricos");
            return;
        }
        
        // Guardar versión del sistema
        FileWriteInteger(handle, 500); // Versión 5.00
        
        // Guardar metadata
        FileWriteInteger(handle, m_totalSystemTrades);
        FileWriteDouble(handle, m_totalSystemProfit);
        FileWriteDouble(handle, m_systemWinRate);
        FileWriteLong(handle, m_systemStartTime);
        
        // Guardar matriz de performance (simplificada)
        for(int ind = 0; ind < 8; ind++) {
            // Guardar métricas (acceso directo sin puntero)
            FileWriteInteger(handle, m_specializations[ind].globalMetrics.buyTrades);
            FileWriteInteger(handle, m_specializations[ind].globalMetrics.buyWins);
            FileWriteDouble(handle, m_specializations[ind].globalMetrics.buyProfit);
            FileWriteInteger(handle, m_specializations[ind].globalMetrics.sellTrades);
            FileWriteInteger(handle, m_specializations[ind].globalMetrics.sellWins);
            FileWriteDouble(handle, m_specializations[ind].globalMetrics.sellProfit);
            FileWriteDouble(handle, m_specializations[ind].globalMetrics.confidenceScore);
        }
        
        FileClose(handle);
        Print("💾 Datos históricos guardados: ", filename);
    }
    
    //+------------------------------------------------------------------+
    //| Cargar datos históricos                                         |
    //+------------------------------------------------------------------+
    void LoadHistoricalData() {
        string filename = "VotingSystem_" + _Symbol + "_Enhanced.bin";
        
        if(!FileIsExist(filename)) {
            Print("ℹ No hay datos históricos previos");
            return;
        }
        
        int handle = FileOpen(filename, FILE_READ|FILE_BIN);
        if(handle == INVALID_HANDLE) return;
        
        // Verificar versión
        int version = FileReadInteger(handle);
        if(version != 500) {
            FileClose(handle);
            Print("⚠ Versión de datos incompatible");
            return;
        }
        
        // Cargar metadata
        m_totalSystemTrades = FileReadInteger(handle);
        m_totalSystemProfit = FileReadDouble(handle);
        m_systemWinRate = FileReadDouble(handle);
        m_systemStartTime = (datetime)FileReadLong(handle);
        
        // Cargar datos básicos de performance (acceso directo sin puntero)
        for(int ind = 0; ind < 8; ind++) {
            m_specializations[ind].globalMetrics.buyTrades = FileReadInteger(handle);
            m_specializations[ind].globalMetrics.buyWins = FileReadInteger(handle);
            m_specializations[ind].globalMetrics.buyProfit = FileReadDouble(handle);
            m_specializations[ind].globalMetrics.sellTrades = FileReadInteger(handle);
            m_specializations[ind].globalMetrics.sellWins = FileReadInteger(handle);
            m_specializations[ind].globalMetrics.sellProfit = FileReadDouble(handle);
            m_specializations[ind].globalMetrics.confidenceScore = FileReadDouble(handle);

            // Recalcular métricas derivadas
            if(m_specializations[ind].globalMetrics.buyTrades > 0) {
                m_specializations[ind].globalMetrics.buyWinRate =
                    (double)m_specializations[ind].globalMetrics.buyWins /
                    m_specializations[ind].globalMetrics.buyTrades;
            }
            if(m_specializations[ind].globalMetrics.sellTrades > 0) {
                m_specializations[ind].globalMetrics.sellWinRate =
                    (double)m_specializations[ind].globalMetrics.sellWins /
                    m_specializations[ind].globalMetrics.sellTrades;
            }
        }
        
        FileClose(handle);
        Print("✅ Datos históricos cargados: ", m_totalSystemTrades, " trades");
    }
    
    //+------------------------------------------------------------------+
    //| Funciones auxiliares para nombres                               |
    //+------------------------------------------------------------------+
    string GetSessionName(ENUM_TRADING_SESSION session) {
        switch(session) {
            case SESSION_ASIA: return "Asia";
            case SESSION_LONDON: return "London";
            case SESSION_NY: return "New York";
            case SESSION_OVERLAP_EU_US: return "EU-US Overlap";
            case SESSION_OVERNIGHT: return "Overnight";
            default: return "Unknown";
        }
    }
    
    string GetVolatilityName(ENUM_VOLATILITY_LEVEL vol) {
        switch(vol) {
            case VOL_ULTRA_LOW: return "Ultra Baja";
            case VOL_LOW: return "Baja";
            case VOL_MEDIUM: return "Media";
            case VOL_HIGH: return "Alta";
            case VOL_EXTREME: return "Extrema";
            default: return "Unknown";
        }
    }
    
    string GetDirectionName(ENUM_MARKET_DIRECTION dir) {
        switch(dir) {
            case DIR_STRONG_BEARISH: return "Fuertemente Bajista";
            case DIR_BEARISH: return "Bajista";
            case DIR_NEUTRAL: return "Neutral";
            case DIR_BULLISH: return "Alcista";
            case DIR_STRONG_BULLISH: return "Fuertemente Alcista";
            default: return "Unknown";
        }
    }
    
    string GetRegimeName(ENUM_MARKET_REGIME regime) {
        switch(regime) {
            case REGIME_TRENDING_UP: return "Tendencia Alcista";
            case REGIME_TRENDING_DOWN: return "Tendencia Bajista";
            case REGIME_RANGING: return "Rango";
            case REGIME_VOLATILE: return "Volátil";
            case REGIME_BREAKOUT: return "Breakout";
            case REGIME_CRISIS: return "Crisis";
            case REGIME_LOW_LIQUIDITY: return "Baja Liquidez";
            case REGIME_TRANSITION: return "Transición";
            default: return "Desconocido";
        }
    }
};

#endif // VOTING_STATISTICS_ENHANCED_MQH