% align first and last max intensity projection


%% USER INPUT

firstMaxIntProjFileDir='/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test2/MAX_m0031_00001_mcor.tif'; 
lastMaxIntProjFileDir='/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test2/MAX_m0031_00075_mcor.tif';


%% MAIN CODE

% get img data
firstMaxIntProj = imread(firstMaxIntProjFileDir);
lastMaxIntProj = imread(lastMaxIntProjFileDir);

% adjust registration parameters - monomodal 
% play with the parameters to get a good balance between precision and
% computation time. The columns on the right are parameters that worked
% well for some subsets of images.
[optimizer, metric] = imregconfig('monomodal');
optimizer.GradientMagnitudeTolerance = 1e-20;   % 1e-4      1e-10    1e-5
optimizer.MinimumStepLength = 0.1 ;             % 1e-5      1e-4     0.1
optimizer.MaximumStepLength = 1;             % 0.0625    0.06       1
optimizer.MaximumIterations = 10000;              % 100       500   10000
optimizer.RelaxationFactor = 0.5;               % 0.5       0.7     0.7

% adjust registration parameters - multimodal
% I started using multimodal but monomodal yields better results - so I
% commented out the multimodal code.
% [optimizer, metric] = imregconfig('multimodal');
% optimizer.InitialRadius = 0.002;    % 0.009     0.005   0.002
% optimizer.Epsilon = 1.5e-8;         % 1.5e-4    1.5e-6  1.5e-6 
% optimizer.GrowthFactor = 1.01;      % 1.05      1.01    1.01
% optimizer.MaximumIterations = 500;  % 100       300     300

% collect registration transformation
tform = imregtform(lastMaxIntProj, firstMaxIntProj, 'translation', optimizer, metric);
xtranslation = tform.T(3,1)
ytranslation = tform.T(3,2)

% align images based on registration transformation
figure;
lastMaxIntProjRegistered = imwarp(lastMaxIntProj,tform,'OutputView',imref2d(size(firstMaxIntProj)));
imshowpair(firstMaxIntProj, lastMaxIntProjRegistered,'Scaling','joint');

translatedImg = imtranslate(lastMaxIntProj,tform.Translation);
figure 
imshow(translatedImg)
