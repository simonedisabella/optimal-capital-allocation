clear
close all
clc

Dataset=readtable("Dataset_risk_measure.xlsx","Sheet","Sheet1","VariableNamingRule","preserve");
Dataset.Date = datetime(Dataset.Date, 'InputFormat', 'dd-mm-yyyy');
data_finale=max(Dataset.Date);
data_inizio=data_finale-years(4);
Dataset=Dataset(Dataset.Date>=data_inizio,:);
titoli=Dataset.Properties.VariableNames(2:end);
titoli_percentuale = strcat(titoli, '_%');
alpha = 0.05;                                                               
tolleranza_check = 1e-8; 
numero_titoli = length(titoli);
parametri = {'Media'; 'Deviazione_standard'; 'Asimmetria'; 'Curtosi'; 'Minimo'; 'Massimo'; 'VaR_5'; 'TCE_5'; 'K_VaR_caso_1'; 'K_TCE_caso_1'; 'K_VaR_%_caso_1'; 'K_TCE_%_caso_1'; 'K_VaR_caso_2'; 'K_TCE_caso_2'; 'K_VaR_%_caso_2'; 'K_TCE_%_caso_2'; 'K_VaR_caso_3'; 'K_TCE_caso_3'; 'K_VaR_%_caso_3'; 'K_TCE_%_caso_3'};
Metriche_rischio_standalone = array2table(NaN(numel(parametri), numero_titoli), 'VariableNames', titoli, 'RowNames', parametri);
for i = 1:numero_titoli
    colonna = titoli{i};
    Dataset.(colonna) = fillmissing(Dataset.(colonna), 'previous');
end
rendimenti_logaritmici = table(Dataset.Date(2:end), 'VariableNames', {'Date'});
for i=1:numero_titoli
    colonna=titoli{i};
    rendimenti_logaritmici.(colonna) = log(Dataset.(colonna)(2:end)) - log(Dataset.(colonna)(1:end-1));
    %% Statistiche descrittive
    fprintf('\n--- Statistiche per %s ---\n', colonna);
    fprintf('Media: %.6f\n', mean(rendimenti_logaritmici.(colonna), 'omitnan'));
    Metriche_rischio_standalone{'Media', colonna} = mean(rendimenti_logaritmici.(colonna), 'omitnan');
    fprintf('Deviazione standard: %.6f\n', std(rendimenti_logaritmici.(colonna), 'omitnan'));
    Metriche_rischio_standalone{'Deviazione_standard', colonna} = std(rendimenti_logaritmici.(colonna), 'omitnan');
    fprintf('Asimmetria: %.6f\n', skewness(rendimenti_logaritmici.(colonna)));
    Metriche_rischio_standalone{'Asimmetria', colonna} = skewness(rendimenti_logaritmici.(colonna));
    fprintf('Curtosi: %.6f\n', kurtosis(rendimenti_logaritmici.(colonna)));
    Metriche_rischio_standalone{'Curtosi', colonna} = kurtosis(rendimenti_logaritmici.(colonna));
    fprintf('Minimo: %.6f\n', min(rendimenti_logaritmici.(colonna)));
    Metriche_rischio_standalone{'Minimo', colonna} = min(rendimenti_logaritmici.(colonna));
    fprintf('Massimo: %.6f\n', max(rendimenti_logaritmici.(colonna)));    
    Metriche_rischio_standalone{'Massimo', colonna} = max(rendimenti_logaritmici.(colonna));
    %% Andamento temporale log-rendimenti
    figure;
    plot(rendimenti_logaritmici.Date,rendimenti_logaritmici.(colonna))
    title(['Andamento temporale rendimenti logaritmici - ' colonna])
    %% Istogramma
    figure;
    histogram(rendimenti_logaritmici.(colonna), 50);
    title(['Istogramma rendimenti - ' colonna]);
    xlabel('Rendimenti logaritmici');
    ylabel('Frequenza');
    grid on;    
    %% QQ-plot
    figure;
    qqplot(rendimenti_logaritmici.(colonna));
    title(['QQ-Plot - ' colonna]);
    xlabel('Quantili teorici');
    ylabel('Quantili empirici');
    grid on;
    %% Calcolo di VaR e TCE al livello alpha = 5% sui rendimenti:
    % prendiamo il 5° percentile dei rendimenti (coda sinistra), lo cambiamo di segno e lo interpretiamo come perdita positiva; 
    % il TCE è la perdita media (in valore assoluto) nei rendimenti al di sotto di tale soglia.
    serie_rendimenti_titolo = rendimenti_logaritmici.(colonna);
    serie_rendimenti_titolo = serie_rendimenti_titolo(~isnan(serie_rendimenti_titolo));    
    quantile_alpha = quantile(serie_rendimenti_titolo, alpha);
    VaR = -quantile_alpha;
    TCE = -mean(serie_rendimenti_titolo(serie_rendimenti_titolo <= quantile_alpha));   
    fprintf('VaR_%2.0f%%: %.6f\n', alpha*100, VaR);
    Metriche_rischio_standalone{'VaR_5', colonna} = VaR;
    fprintf('TCE_%2.0f%%: %.6f\n', alpha*100, TCE);
    Metriche_rischio_standalone{'TCE_5', colonna} = TCE;
end

%% Costruisco il portafoglio equi-pesato (1/n) sui rendimenti logaritmici
pesi_p_equipesato = ones(1,numero_titoli)/numero_titoli;
rendimenti_logaritmici.portafoglio_equipesato = rendimenti_logaritmici{:,2:end}*pesi_p_equipesato';
serie_rendimenti_portafoglio = rendimenti_logaritmici.portafoglio_equipesato;
serie_rendimenti_portafoglio = serie_rendimenti_portafoglio(~isnan(serie_rendimenti_portafoglio));
quantile_alpha = quantile(serie_rendimenti_portafoglio,alpha);
VaR_portafoglio_equipesato = -quantile_alpha;
TCE_portafoglio_equipesato = -mean(serie_rendimenti_portafoglio(serie_rendimenti_portafoglio <= quantile_alpha));
fprintf('\n--- Misure di rischio portafoglio equi-pesato ---\n');
fprintf('VaR_%2.0f%%: %.6f\n', alpha*100, VaR_portafoglio_equipesato);
fprintf('TCE_%2.0f%%: %.6f\n', alpha*100, TCE_portafoglio_equipesato);

%% Costruisco il portafoglio optimal allocation con D quadratica quando K è VaR/TCE
K_VaR = VaR_portafoglio_equipesato;
K_TCE = TCE_portafoglio_equipesato;

% Caso 1: ζi ≡ 1
somma_medie_rendimenti_titoli = 0;   
media_rendimenti_titoli_p_negativo = zeros(numero_titoli,1);
for i = 1:numero_titoli
    colonna = titoli{i};
    media_rendimenti_titoli_p_negativo(i) = pesi_p_equipesato(i) * mean(rendimenti_logaritmici{:, colonna}, 'omitnan');
    somma_medie_rendimenti_titoli = somma_medie_rendimenti_titoli + media_rendimenti_titoli_p_negativo(i);
end
for i = 1:numero_titoli
    colonna = titoli{i};
    K_VaR_i = -media_rendimenti_titoli_p_negativo(i) + pesi_p_equipesato(i) * (K_VaR - (-somma_medie_rendimenti_titoli));
    K_TCE_i = -media_rendimenti_titoli_p_negativo(i) + pesi_p_equipesato(i) * (K_TCE - (-somma_medie_rendimenti_titoli));
    Metriche_rischio_standalone{'K_VaR_caso_1', colonna} = K_VaR_i;
    Metriche_rischio_standalone{'K_TCE_caso_1', colonna} = K_TCE_i;
end
somma_K_VaR = sum(Metriche_rischio_standalone{'K_VaR_caso_1', titoli});
Metriche_rischio_standalone{'K_VaR_%_caso_1', titoli} = 100 * Metriche_rischio_standalone{'K_VaR_caso_1', titoli}/somma_K_VaR;
somma_K_TCE = sum(Metriche_rischio_standalone{'K_TCE_caso_1', titoli});
Metriche_rischio_standalone{'K_TCE_%_caso_1', titoli} = 100 * Metriche_rischio_standalone{'K_TCE_caso_1', titoli}/somma_K_TCE;
violazioni = strings(0,1);
check_full_VaR = abs(somma_K_VaR - K_VaR) < tolleranza_check;
check_full_TCE = abs(somma_K_TCE - K_TCE) < tolleranza_check;
if ~check_full_VaR
    violazioni(end+1) = "Full allocation VaR: sum(K_i) != K_VaR";
end
if ~check_full_TCE
    violazioni(end+1) = "Full allocation TCE: sum(K_i) != K_TCE";
end
check_somma_pesi = abs(sum(pesi_p_equipesato) - 1) < tolleranza_check;
check_pesi_nonneg = all(pesi_p_equipesato >= -tolleranza_check);
if ~check_somma_pesi
    violazioni(end+1) = "Vincolo pesi: sum(v_i) != 1";
end
if ~check_pesi_nonneg
    violazioni(end+1) = "Vincolo pesi: esistono v_i < 0";
end
check_Ezeta = true;
check_zeta_nonneg = true;
K_VaR_vettore = Metriche_rischio_standalone{'K_VaR_caso_1', titoli};
K_TCE_vettore = Metriche_rischio_standalone{'K_TCE_caso_1', titoli};
check_finiti = all(isfinite(K_VaR_vettore)) && all(isfinite(K_TCE_vettore));
if ~check_finiti
    violazioni(end+1) = "Valori non finiti: NaN/Inf in K_i";
end
if isempty(violazioni)
    fprintf('\n ---- [OK] Caso 1: tutte le condizioni del paper risultano rispettate.----');
else
    fprintf('\n ---- [KO] Caso 1: condizioni NON rispettate:----\n');
    fprintf(' - %s\n', violazioni);
end
fprintf('\n --- Capital allocation proporzionale (VaR) ---\n');
disp(Metriche_rischio_standalone(["K_VaR_caso_1", "K_VaR_%_caso_1"],:))
fprintf(' --- Capital allocation proporzionale (TCE) ---\n');
disp(Metriche_rischio_standalone(["K_TCE_caso_1", "K_TCE_%_caso_1"],:))

% Aggregate Portfolio Driven Allocations
% Caso 2: ζ basata sulla coda del portafoglio
p_denominatore = length(rendimenti_logaritmici.portafoglio_equipesato(rendimenti_logaritmici.portafoglio_equipesato <= quantile_alpha)) / size(rendimenti_logaritmici,1);
zeta = double(rendimenti_logaritmici.portafoglio_equipesato <= quantile_alpha) / p_denominatore;
somma_medie_rendimenti_titoli = 0;
media_rendimenti_titoli_p_negativo = zeros(numero_titoli,1);
for i = 1:numero_titoli
    colonna = titoli{i};
    media_rendimenti_titoli_p_negativo(i) = mean(zeta .* (pesi_p_equipesato(i) * rendimenti_logaritmici{:, colonna}), 'omitnan');
    somma_medie_rendimenti_titoli = somma_medie_rendimenti_titoli + media_rendimenti_titoli_p_negativo(i);
end
for i = 1:numero_titoli
    colonna = titoli{i};
    K_VaR_i = -media_rendimenti_titoli_p_negativo(i) + pesi_p_equipesato(i) * (K_VaR - (-somma_medie_rendimenti_titoli));
    K_TCE_i = -media_rendimenti_titoli_p_negativo(i) + pesi_p_equipesato(i) * (K_TCE - (-somma_medie_rendimenti_titoli));
    Metriche_rischio_standalone{'K_VaR_caso_2', colonna} = K_VaR_i;
    Metriche_rischio_standalone{'K_TCE_caso_2', colonna} = K_TCE_i;
end
somma_K_VaR  = sum(Metriche_rischio_standalone{'K_VaR_caso_2', titoli});
Metriche_rischio_standalone{'K_VaR_%_caso_2', titoli} = 100 * Metriche_rischio_standalone{'K_VaR_caso_2', titoli}/somma_K_VaR;
somma_K_TCE = sum(Metriche_rischio_standalone{'K_TCE_caso_2', titoli});
Metriche_rischio_standalone{'K_TCE_%_caso_2', titoli} = 100 * Metriche_rischio_standalone{'K_TCE_caso_2', titoli}/somma_K_TCE;
violazioni = strings(0,1);
check_full_VaR = abs(somma_K_VaR - K_VaR) < tolleranza_check;
check_full_TCE = abs(somma_K_TCE - K_TCE) < tolleranza_check;
if ~check_full_VaR
    violazioni(end+1) = "Full allocation VaR: sum(K_i) != K_VaR";
end
if ~check_full_TCE
    violazioni(end+1) = "Full allocation TCE: sum(K_i) != K_TCE";
end
check_somma_pesi = abs(sum(pesi_p_equipesato) - 1) < tolleranza_check;
check_pesi_nonneg = all(pesi_p_equipesato >= -tolleranza_check);
if ~check_somma_pesi
    violazioni(end+1) = "Vincolo pesi: sum(v_i) != 1";
end
if ~check_pesi_nonneg
    violazioni(end+1) = "Vincolo pesi: esistono v_i < 0";
end
maschera_finiti_zeta = isfinite(zeta);
Ezeta = mean(zeta(maschera_finiti_zeta), 'omitnan');
check_Ezeta = abs(Ezeta - 1) < tolleranza_check;
check_zeta_nonneg = all(zeta(maschera_finiti_zeta) >= -tolleranza_check);
if ~check_Ezeta
    violazioni(end+1) = "Vincolo zeta: E[zeta] != 1";
end
if ~check_zeta_nonneg
    violazioni(end+1) = "Vincolo zeta: esistono zeta < 0";
end
K_VaR_vettore = Metriche_rischio_standalone{'K_VaR_caso_2', titoli};
K_TCE_vettore = Metriche_rischio_standalone{'K_TCE_caso_2', titoli};
check_finiti = all(isfinite(K_VaR_vettore)) && all(isfinite(K_TCE_vettore));
if ~check_finiti
    violazioni(end+1) = "Valori non finiti: NaN/Inf in K_i";
end
if isempty(violazioni)
    fprintf('\n ---- [OK] Caso 2: tutte le condizioni del paper risultano rispettate.----');
else
    fprintf('\n ---- [KO] Caso 2: condizioni NON rispettate: ---- \n');
    fprintf(' - %s\n', violazioni);
end
fprintf('\n --- Capital allocation proporzionale (VaR) --- \n');
disp(Metriche_rischio_standalone(["K_VaR_caso_2", "K_VaR_%_caso_2"],:))
fprintf(' --- Capital allocation proporzionale (TCE) --- \n');
disp(Metriche_rischio_standalone(["K_TCE_caso_2", "K_TCE_%_caso_2"],:))

% Aggregate Business Unit Driven Allocations
% Caso 3
somma_medie_rendimenti_titoli = 0;
media_rendimenti_titoli_negativi = zeros(numero_titoli,1);
for i = 1:numero_titoli
    colonna = titoli{i};
    maschera_coda = (-pesi_p_equipesato(i) * rendimenti_logaritmici{:, colonna} >= pesi_p_equipesato(i) * Metriche_rischio_standalone{'VaR_5', colonna});
    p_denominatore = sum(maschera_coda) / size(rendimenti_logaritmici,1);
    zeta = double(maschera_coda) / p_denominatore;
    media_rendimenti_titoli_negativi(i) = mean(zeta .* (pesi_p_equipesato(i) * rendimenti_logaritmici{:, colonna}), 'omitnan');
    somma_medie_rendimenti_titoli = somma_medie_rendimenti_titoli + media_rendimenti_titoli_negativi(i);
end
for i = 1:numero_titoli
    colonna = titoli{i};
    K_VaR_i = -media_rendimenti_titoli_negativi(i) + pesi_p_equipesato(i) * (K_VaR - (-somma_medie_rendimenti_titoli));
    K_TCE_i = -media_rendimenti_titoli_negativi(i) + pesi_p_equipesato(i) * (K_TCE - (-somma_medie_rendimenti_titoli));
    Metriche_rischio_standalone{'K_VaR_caso_3', colonna} = K_VaR_i;
    Metriche_rischio_standalone{'K_TCE_caso_3', colonna} = K_TCE_i;
end
somma_K_VaR  = sum(Metriche_rischio_standalone{'K_VaR_caso_3', titoli});
Metriche_rischio_standalone{'K_VaR_%_caso_3', titoli} = 100 * Metriche_rischio_standalone{'K_VaR_caso_3', titoli}/somma_K_VaR;
somma_K_TCE = sum(Metriche_rischio_standalone{'K_TCE_caso_3', titoli});
Metriche_rischio_standalone{'K_TCE_%_caso_3', titoli} = 100 * Metriche_rischio_standalone{'K_TCE_caso_3', titoli}/somma_K_TCE;
violazioni = strings(0,1);
check_full_VaR = abs(somma_K_VaR - K_VaR) < tolleranza_check;
check_full_TCE = abs(somma_K_TCE - K_TCE) < tolleranza_check;
if ~check_full_VaR
    violazioni(end+1) = "Full allocation VaR: sum(K_i) != K_VaR";
end
if ~check_full_TCE
    violazioni(end+1) = "Full allocation TCE: sum(K_i) != K_TCE";
end
check_somma_pesi = abs(sum(pesi_p_equipesato) - 1) < tolleranza_check;
check_pesi_nonneg = all(pesi_p_equipesato >= -tolleranza_check);
if ~check_somma_pesi
    violazioni(end+1) = "Vincolo pesi: sum(v_i) != 1";
end
if ~check_pesi_nonneg
    violazioni(end+1) = "Vincolo pesi: esistono v_i < 0";
end
max_dev_Ezeta = 0;
check_zeta_nonneg = true;
for i = 1:numero_titoli
    colonna = titoli{i};
    maschera_coda_chk = (-pesi_p_equipesato(i) * rendimenti_logaritmici{:, colonna} >= pesi_p_equipesato(i) * Metriche_rischio_standalone{'VaR_5', colonna});
    p_den_chk = sum(maschera_coda_chk) / size(rendimenti_logaritmici,1);
    zeta_chk = double(maschera_coda_chk) / p_den_chk;
    Ezeta_i = mean(zeta_chk(isfinite(zeta_chk)), 'omitnan');
    max_dev_Ezeta = max(max_dev_Ezeta, abs(Ezeta_i - 1));
    check_zeta_nonneg = check_zeta_nonneg && all(zeta_chk(isfinite(zeta_chk)) >= -tolleranza_check);
end
check_Ezeta = max_dev_Ezeta < tolleranza_check;
if ~check_Ezeta
    violazioni(end+1) = "Vincolo zeta_i: max |E[zeta_i]-1| >= tol";
end
if ~check_zeta_nonneg
    violazioni(end+1) = "Vincolo zeta_i: esistono zeta_i < 0";
end
K_VaR_vettore = Metriche_rischio_standalone{'K_VaR_caso_3', titoli};
K_TCE_vettore = Metriche_rischio_standalone{'K_TCE_caso_3', titoli};
check_finiti = all(isfinite(K_VaR_vettore)) && all(isfinite(K_TCE_vettore));
if ~check_finiti
    violazioni(end+1) = "Valori non finiti: NaN/Inf in K_i";
end
if isempty(violazioni)
    fprintf('\n ---- [OK] Caso 3: tutte le condizioni del paper risultano rispettate. ----');
else
    fprintf('\n ---- [KO] Caso 3: condizioni NON rispettate: ----\n');
    fprintf(' - %s\n', violazioni);
end
fprintf('\n --- Capital allocation proporzionale (VaR) ---\n');
disp(Metriche_rischio_standalone(["K_VaR_caso_3", "K_VaR_%_caso_3"],:))
fprintf(' --- Capital allocation proporzionale (TCE) ---\n');
disp(Metriche_rischio_standalone(["K_TCE_caso_3", "K_TCE_%_caso_3"],:))

%% Rolling Capital Allocation (finestra 800)
% Media shrinkata: w_globale * media_globale + w_finestra * media_finestra
window = 800;
peso_media_globale = 0.60;   
peso_media_finestra = 0.40;   
if abs((peso_media_globale + peso_media_finestra) - 1) > 1e-12
    error('I pesi devono sommare a 1: peso_media_globale + peso_media_finestra = 1');
end
matrice_rendimenti = rendimenti_logaritmici{:, 2:(numero_titoli+1)}; 
T = size(matrice_rendimenti, 1);
numero_finestre = T - window + 1;
date_fine_window = rendimenti_logaritmici.Date(window:end);
pesi = pesi_p_equipesato(:); 
% Caso 1 (zeta = 1): E[v_i * R_i]
media_globale_caso_1 = (pesi .* mean(matrice_rendimenti, 1, 'omitnan')'); 
% Caso 2 (zeta basata sulla coda del portafoglio): E[zeta * v_i * R_i]
maschera_coda_completo_portafoglio  = ( (matrice_rendimenti * pesi) <= quantile_alpha );
zeta_completo_caso_2 = double(maschera_coda_completo_portafoglio) ./ max(sum(maschera_coda_completo_portafoglio) / T, eps);
media_globale_caso_2 = NaN(numero_titoli, 1);
for i = 1:numero_titoli
    media_globale_caso_2(i) = mean(zeta_completo_caso_2 .* (pesi(i) * matrice_rendimenti(:, i)), 'omitnan');
end
% Caso 3 (zeta_i basata sulla coda del singolo titolo): E[zeta_i * v_i * R_i]
media_globale_caso_3 = NaN(numero_titoli, 1);
for i = 1:numero_titoli
    colonna = titoli{i};
    maschera_coda_completo_i = (-pesi(i) * matrice_rendimenti(:, i) >= pesi(i) * Metriche_rischio_standalone{'VaR_5', colonna});
    zeta_completo_i = double(maschera_coda_completo_i) ./ max(sum(maschera_coda_completo_i) / T, eps);
    media_globale_caso_3(i) = mean(zeta_completo_i .* (pesi(i) * matrice_rendimenti(:, i)), 'omitnan');
end
K_portafoglio_VaR_rolling = NaN(numero_finestre, 1);
K_portafoglio_TCE_rolling = NaN(numero_finestre, 1);
allocazione_VaR_caso_1 = NaN(numero_finestre, numero_titoli);
allocazione_TCE_caso_1 = NaN(numero_finestre, numero_titoli);
allocazione_VaR_caso_2 = NaN(numero_finestre, numero_titoli);
allocazione_TCE_caso_2 = NaN(numero_finestre, numero_titoli);
allocazione_VaR_caso_3 = NaN(numero_finestre, numero_titoli);
allocazione_TCE_caso_3 = NaN(numero_finestre, numero_titoli);
VaR_titoli_rolling = NaN(numero_finestre, numero_titoli);
TCE_titoli_rolling = NaN(numero_finestre, numero_titoli);
for k = 1:numero_finestre
    rendimenti_window = matrice_rendimenti(k:k + window - 1, :); 
    rendimenti_portafoglio_window = rendimenti_window * pesi;                    
    quantile_portafoglio = quantile(rendimenti_portafoglio_window, alpha);
    VaR_portafoglio = -quantile_portafoglio;
    TCE_portafoglio = -mean(rendimenti_portafoglio_window(rendimenti_portafoglio_window <= quantile_portafoglio), 'omitnan');
    K_portafoglio_VaR_rolling(k) = VaR_portafoglio;
    K_portafoglio_TCE_rolling(k) = TCE_portafoglio;    
    % Caso 1: zeta = 1
    media_finestra_caso_1 = (pesi .* mean(rendimenti_window, 1, 'omitnan')'); 
    media_shrink_caso_1 = peso_media_globale * media_globale_caso_1 + peso_media_finestra * media_finestra_caso_1;
    somma_medie_1 = sum(media_shrink_caso_1);
    K_i_VaR_1 = -media_shrink_caso_1 + pesi * (VaR_portafoglio - (-somma_medie_1));
    K_i_TCE_1 = -media_shrink_caso_1 + pesi * (TCE_portafoglio - (-somma_medie_1));
    allocazione_VaR_caso_1(k, :) = K_i_VaR_1';
    allocazione_TCE_caso_1(k, :) = K_i_TCE_1';
    % Caso 2: zeta basata sulla coda del portafoglio (in finestra)
    maschera_coda_portafoglio = (rendimenti_portafoglio_window <= quantile_portafoglio);
    zeta_portafoglio_window = double(maschera_coda_portafoglio) ./ max(sum(maschera_coda_portafoglio) / window, eps);
    media_finestra_caso_2 = NaN(numero_titoli, 1);
    for i = 1:numero_titoli
        media_finestra_caso_2(i) = mean(zeta_portafoglio_window .* (pesi(i) * rendimenti_window(:, i)), 'omitnan');
    end
    media_shrink_caso_2 = peso_media_globale  * media_globale_caso_2 + peso_media_finestra * media_finestra_caso_2;
    somma_medie_2 = sum(media_shrink_caso_2);
    K_i_VaR_2 = -media_shrink_caso_2 + pesi * (VaR_portafoglio - (-somma_medie_2));
    K_i_TCE_2 = -media_shrink_caso_2 + pesi * (TCE_portafoglio - (-somma_medie_2));
    allocazione_VaR_caso_2(k, :) = K_i_VaR_2';
    allocazione_TCE_caso_2(k, :) = K_i_TCE_2';
    % CASO 3: zeta_i basata sulla coda del singolo titolo (in finestra)
    media_finestra_caso_3 = NaN(numero_titoli, 1);
    for i = 1:numero_titoli
        rendimenti_i = rendimenti_window(:, i);
        quantile_i = quantile(rendimenti_i, alpha);
        VaR_i = -quantile_i;
        TCE_i = -mean(rendimenti_i(rendimenti_i <= quantile_i), 'omitnan');
        VaR_titoli_rolling(k, i) = VaR_i;
        TCE_titoli_rolling(k, i) = TCE_i;
        maschera_coda_i = (-pesi(i) * rendimenti_i >= pesi(i) * VaR_i);
        zeta_i_finestra = double(maschera_coda_i) ./ max(sum(maschera_coda_i) / window, eps);
        media_finestra_caso_3(i) = mean(zeta_i_finestra .* (pesi(i) * rendimenti_i), 'omitnan');
    end
    media_shrink_caso_3 = peso_media_globale  * media_globale_caso_3 + peso_media_finestra * media_finestra_caso_3;
    somma_medie_3 = sum(media_shrink_caso_3);
    K_i_VaR_3 = -media_shrink_caso_3 + pesi * (VaR_portafoglio - (-somma_medie_3));
    K_i_TCE_3 = -media_shrink_caso_3 + pesi * (TCE_portafoglio - (-somma_medie_3));
    allocazione_VaR_caso_3(k, :) = K_i_VaR_3';
    allocazione_TCE_caso_3(k, :) = K_i_TCE_3';
end
percentuale_VaR_caso_1 = 100 * allocazione_VaR_caso_1 ./ sum(allocazione_VaR_caso_1, 2);
percentuale_TCE_caso_1 = 100 * allocazione_TCE_caso_1 ./ sum(allocazione_TCE_caso_1, 2);
percentuale_VaR_caso_2 = 100 * allocazione_VaR_caso_2 ./ sum(allocazione_VaR_caso_2, 2);
percentuale_TCE_caso_2 = 100 * allocazione_TCE_caso_2 ./ sum(allocazione_TCE_caso_2, 2);
percentuale_VaR_caso_3 = 100 * allocazione_VaR_caso_3 ./ sum(allocazione_VaR_caso_3, 2);
percentuale_TCE_caso_3 = 100 * allocazione_TCE_caso_3 ./ sum(allocazione_TCE_caso_3, 2);
scarto_VaR_caso_1 = abs(sum(allocazione_VaR_caso_1, 2) - K_portafoglio_VaR_rolling);
scarto_TCE_caso_1 = abs(sum(allocazione_TCE_caso_1, 2) - K_portafoglio_TCE_rolling);
scarto_VaR_caso_2 = abs(sum(allocazione_VaR_caso_2, 2) - K_portafoglio_VaR_rolling);
scarto_TCE_caso_2 = abs(sum(allocazione_TCE_caso_2, 2) - K_portafoglio_TCE_rolling);
scarto_VaR_caso_3 = abs(sum(allocazione_VaR_caso_3, 2) - K_portafoglio_VaR_rolling);
scarto_TCE_caso_3 = abs(sum(allocazione_TCE_caso_3, 2) - K_portafoglio_TCE_rolling);
fprintf('\n--- CHECK FULL-ALLOCATION rolling (tolleranza = %.1e) ---\n', tolleranza_check);
fprintf('Caso 1: violazioni VaR=%d | violazioni TCE=%d\n', sum(scarto_VaR_caso_1>tolleranza_check), sum(scarto_TCE_caso_1>tolleranza_check));
fprintf('Caso 2: violazioni VaR=%d | violazioni TCE=%d\n', sum(scarto_VaR_caso_2>tolleranza_check), sum(scarto_TCE_caso_2>tolleranza_check));
fprintf('Caso 3: violazioni VaR=%d | violazioni TCE=%d\n', sum(scarto_VaR_caso_3>tolleranza_check), sum(scarto_TCE_caso_3>tolleranza_check));
date_inizio_window = rendimenti_logaritmici.Date(1:(T - window + 1));   
date_fine_window = rendimenti_logaritmici.Date(window:end);           
Tabella_VaR_caso_1 = array2table(allocazione_VaR_caso_1, 'VariableNames', titoli);
Tabella_VaR_caso_1 = addvars(Tabella_VaR_caso_1, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_TCE_caso_1 = array2table(allocazione_TCE_caso_1, 'VariableNames', titoli);
Tabella_TCE_caso_1 = addvars(Tabella_TCE_caso_1, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_percentuale_VaR_caso_1 = array2table(percentuale_VaR_caso_1, 'VariableNames', titoli);
Tabella_percentuale_VaR_caso_1 = addvars(Tabella_percentuale_VaR_caso_1, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_percentuale_TCE_caso_1 = array2table(percentuale_TCE_caso_1, 'VariableNames', titoli);
Tabella_percentuale_TCE_caso_1 = addvars(Tabella_percentuale_TCE_caso_1, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_VaR_caso_2 = array2table(allocazione_VaR_caso_2, 'VariableNames', titoli);
Tabella_VaR_caso_2 = addvars(Tabella_VaR_caso_2, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_TCE_caso_2 = array2table(allocazione_TCE_caso_2, 'VariableNames', titoli);
Tabella_TCE_caso_2 = addvars(Tabella_TCE_caso_2, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_percentuale_VaR_caso_2 = array2table(percentuale_VaR_caso_2, 'VariableNames', titoli);
Tabella_percentuale_VaR_caso_2 = addvars(Tabella_percentuale_VaR_caso_2, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_percentuale_TCE_caso_2 = array2table(percentuale_TCE_caso_2, 'VariableNames', titoli);
Tabella_percentuale_TCE_caso_2 = addvars(Tabella_percentuale_TCE_caso_2, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_VaR_caso_3 = array2table(allocazione_VaR_caso_3, 'VariableNames', titoli);
Tabella_VaR_caso_3 = addvars(Tabella_VaR_caso_3, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_TCE_caso_3 = array2table(allocazione_TCE_caso_3, 'VariableNames', titoli);
Tabella_TCE_caso_3 = addvars(Tabella_TCE_caso_3, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_percentuale_VaR_caso_3 = array2table(percentuale_VaR_caso_3, 'VariableNames', titoli);
Tabella_percentuale_VaR_caso_3 = addvars(Tabella_percentuale_VaR_caso_3, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Tabella_percentuale_TCE_caso_3 = array2table(percentuale_TCE_caso_3, 'VariableNames', titoli);
Tabella_percentuale_TCE_caso_3 = addvars(Tabella_percentuale_TCE_caso_3, date_inizio_window, date_fine_window, 'Before', 1, 'NewVariableNames', {'Data_Inizio','Data_Fine'});
Rolling = struct();
Rolling.Caso1 = struct();
Rolling.Caso1.VaR = Tabella_VaR_caso_1;
Rolling.Caso1.TCE = Tabella_TCE_caso_1;
Rolling.Caso1.Percentuale_VaR = Tabella_percentuale_VaR_caso_1;
Rolling.Caso1.Percentuale_TCE = Tabella_percentuale_TCE_caso_1;
Rolling.Caso2 = struct();
Rolling.Caso2.VaR = Tabella_VaR_caso_2;
Rolling.Caso2.TCE = Tabella_TCE_caso_2;
Rolling.Caso2.Percentuale_VaR = Tabella_percentuale_VaR_caso_2;
Rolling.Caso2.Percentuale_TCE = Tabella_percentuale_TCE_caso_2;
Rolling.Caso3 = struct();
Rolling.Caso3.VaR = Tabella_VaR_caso_3;
Rolling.Caso3.TCE = Tabella_TCE_caso_3;
Rolling.Caso3.Percentuale_VaR = Tabella_percentuale_VaR_caso_3;
Rolling.Caso3.Percentuale_TCE = Tabella_percentuale_TCE_caso_3;
fprintf('\n[OK] Rolling capital allocation completata: %d finestre (window=%d).\n', numero_finestre, window);
fprintf('Shrinkage medie: %.0f%% globale, %.0f%% finestra.\n', 100*peso_media_globale, 100*peso_media_finestra);

%% Grafici (2 plot per figura): Percentuali + K
crea_grafici_rolling(Rolling.Caso1.VaR, Rolling.Caso1.Percentuale_VaR, titoli, 'Caso 1', 'VaR');
crea_grafici_rolling(Rolling.Caso1.TCE, Rolling.Caso1.Percentuale_TCE, titoli, 'Caso 1', 'TCE');
crea_grafici_rolling(Rolling.Caso2.VaR, Rolling.Caso2.Percentuale_VaR, titoli, 'Caso 2', 'VaR');
crea_grafici_rolling(Rolling.Caso2.TCE, Rolling.Caso2.Percentuale_TCE, titoli, 'Caso 2', 'TCE');
crea_grafici_rolling(Rolling.Caso3.VaR, Rolling.Caso3.Percentuale_VaR, titoli, 'Caso 3', 'VaR');
crea_grafici_rolling(Rolling.Caso3.TCE, Rolling.Caso3.Percentuale_TCE, titoli, 'Caso 3', 'TCE');

%% Tabella riassuntiva
Risultati = struct();
Risultati.Metriche_rischio_standalone = Metriche_rischio_standalone;
Risultati.Equipesato = struct();
Risultati.Equipesato.VaR_5  = VaR_portafoglio_equipesato;
Risultati.Equipesato.TCE_5 = TCE_portafoglio_equipesato;
Risultati.Rolling = Rolling;                                
clearvars -except Risultati;

function crea_grafici_rolling(Tabella_K, Tabella_Percentuali, titoli, etichetta_caso, metrica_K)
    date_fine_window = Tabella_Percentuali.Data_Fine;
    if ~isdatetime(date_fine_window)
        date_fine_window = datetime(date_fine_window);
    end
    percentuali = Tabella_Percentuali{:, 3:end};
    K_titoli = Tabella_K{:, 3:end};
    figure;
    % Plot 1: Percentuali
    subplot(2,1,1);
    plot(date_fine_window, percentuali);
    title(['Andamento capital allocation (percentuale) - ' etichetta_caso ' - K = ' metrica_K ' rolling']);
    xlabel('Data (fine window)');
    ylabel('Allocazione %');
    grid on;
    legend(titoli, 'Location', 'eastoutside');
    % Plot 2: K 
    subplot(2,1,2);
    plot(date_fine_window, K_titoli);
    title(['Andamento capital allocation (K_i) - ' etichetta_caso ' - K = ' metrica_K ' rolling']);
    xlabel('Data (fine window)');
    ylabel('K_i');
    grid on;
    legend(titoli, 'Location', 'eastoutside');
end