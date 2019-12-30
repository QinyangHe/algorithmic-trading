load('inputData_ETF.mat', 'tday', 'syms', 'cl'); %strings after file name are variables
idxA = find(strcmp('EWA', syms)); %strcmp: compare two strings; find: return the index of nonzero value
idxC = find(strcmp('EWC', syms));

x = cl(:, idxA);
y = cl(:, idxC);
idxI = find(strcmp('IGE', syms));
z = cl(:, idxI);
matrix = [x y z];
csvwrite('inputData_ETF.csv', matrix);
