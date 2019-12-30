% 1 minute data on EWA-EWC
load('inputData_ETF.mat', 'tday', 'syms', 'cl'); %strings after file name are variables
idxA = find(strcmp('EWA', syms)); %strcmp: compare two strings; find: return the index of nonzero value
idxC = find(strcmp('EWC', syms));

x = cl(:, idxA);
y = cl(:, idxC);
plot(x);
hold on;
plot(y, 'g');
legend('EWA', 'EWC');
figure;
scatter(x, y);
figure;

regression_result = ols(y, [x ones(size(x))]);
hedgeRatio = regression_result.beta(1);

plot(y-hedgeRatio*x);

% assume a non-zero offset but no drift, with lag=1
results = cadf(y, x, 0, 1);
prt(results)

y2 = [y, x];
results = johansen(y2, 0, 1); % johansen test with non-zero drift, and with the lag k=1
prt(results)

% Adding IGE to the portfolio
idxI = find(strcmp('IGE', syms));
z = cl(:, idxI);
y3 = [y2, z];

results = johansen(y3, 0, 1);
prt(results)

results.eig;
results.evec;

yport = sum(repmat(results.evec(:,1)',[size(y3,1) 1]).*y3, 2);% (net) market value of the portfolio
tobesum = repmat(results.evec(:, 1)', [size(y3, 1) 1])

%Find the value of lambda and thus the halflife of mean reversion by linear
%regression fit
ylag = lag(yport, 1);
deltaY = yport - ylag;
deltaY(1)=[]; % Regression functions cannot handle the NaN in the first bar of the time series
ylag(1) = [];
regress_results = ols(deltaY, [ylag ones(size(ylag))]);
halflife = -log(2)/regress_results.beta(1);
fprintf(1, 'halflife=%f days\n', halflife);

%Apply a simple linear mean reversion to EWA-EWC-IGE
lookback = round(halflife); %setting lookback to the halflife found above

numUnits = -(yport-movingAvg(yport, lookback))./movingStd(yport, lookback);
%capital invested in portfolio in dollars.
positions = repmat(numUnits, [1 size(y3, 2)]).*repmat(results.evec(:, 1)',[size(y3, 1) 1]).*y3;
pnl=sum(lag(positions, 1).*(y3-lag(y3, 1))./lag(y3, 1), 2); %daily pl of the strategy
ret = pnl./sum(abs(lag(positions, 1)), 2); % return is pl divided by gross market value of porfolio
ret(isnan(ret))=0;

figure;
plot(cumprod(1+ret)-1); % cumulative compounded return

fprintf(1, 'APR=%f Sharpe=%f\n', prod(1+ret).^(252/length(ret))-1, sqrt(252)*mean(ret)/std(ret));