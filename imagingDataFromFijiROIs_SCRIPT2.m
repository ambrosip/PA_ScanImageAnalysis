%{ 
DOCUMENTATION
Created: 2024 10 ??
Last edited on: 2024 11 09
Works? Yes
Author: PA

!! search for ALERT and ASSUMPTION to read important info

DEPENDS on:
From others > ReadImageJROI
    https://www.mathworks.com/matlabcentral/fileexchange/32479-readimagejroi

TO DO: 
Explain user inputs
Automate generation of max int projection instead of providing file dir
Add letter before date if mcor.tiff file starts with numbers - something
about structure fields not being allowed to start with numbers?
%}

% clear all
% close all


%% USER INPUT

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

analyzeOdorPulse = 1;
xmax = ceil(img_dur_in_s); % seconds
ymax = 10; % z-score

% gcamp8 odor1 glom a20250303_m0041_00105_mcor to a20250303_m0041_00204_mcor
timingFile=h5_file_dir;
imgDir='/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/odor 1';
firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00105_mcor.tif'; 
lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00204_mcor.tif';
roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/RoiSet_glom_acq105.zip';
motionCorrectionAcrossFiles = 0;    % no: 0     yes: 1
plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers


% inputs for other datasets (may be outdated!):

% % gcamp8 odor2 glom a20250303_m0041_00105_mcor to a20250303_m0041_00204_mcor
% timingFile=h5_file_dir;
% imgDir='/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/odor 2';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00105_mcor.tif'; 
% lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00204_mcor.tif';
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/RoiSet_glom_acq105.zip';
% motionCorrectionAcrossFiles = 0;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % gcamp8 odor2 somas a20250303_m0041_00105_mcor to a20250303_m0041_00204_mcor
% timingFile=h5_file_dir;
% imgDir='/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/odor 2';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00105_mcor.tif'; 
% lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00204_mcor.tif';
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/RoiSet_somas_acq105.zip';
% motionCorrectionAcrossFiles = 1;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % gcamp8 odor1 somas a20250303_m0041_00105_mcor to a20250303_m0041_00204_mcor
% timingFile=h5_file_dir;
% imgDir='/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/odor 1';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00105_mcor.tif'; 
% lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/STD_20250303_m0041_00204_mcor.tif';
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)/fiji/RoiSet_somas_acq105.zip';
% motionCorrectionAcrossFiles = 1;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % gcamp8 a20250106_m0041_00017_mcor
% timingFile='/Users/priscilla/Documents/Local - Moss Lab/20250106/20250106_m0041_00011.h5';
% imgDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/mcor';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/STD_20250106_m0041_00013_mcor.tif'; 
% lastMaxIntProjFileDir = firstMaxIntProjFileDir;
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/AVG_20250106_m0041_00013_mcor_roi.zip';
% motionCorrectionAcrossFiles = 0;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % gcamp8 a20250106_m0041_00017_mcor
% timingFile='/Users/priscilla/Documents/Local - Moss Lab/20250106/20250106_m0041_00015.h5';
% imgDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/mcor';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/STD_20250106_m0041_00017_mcor.tif'; 
% lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/STD_20250106_m0041_00017_mcor.tif';
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/20250106/analyzed/STD_20250106_m0041_00017_mcor_roi.zip';
% motionCorrectionAcrossFiles = 0;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % dlight area2
% timingFile='/Users/priscilla/Documents/Local - Moss Lab/ACC/20241113/Area2/20241113_1723_m0034__00002.h5';
% imgDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241113/Area2/mcor';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241113/Area2/STD_20241113_1723_m0034__00002_mcor.tif'; 
% lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241113/Area2/STD_20241113_1723_m0034__00002_mcor.tif';
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241113/Area2/RoiSet.zip';
% motionCorrectionAcrossFiles = 0;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % m0027 test 1
% timingFile='/Users/priscilla/Documents/Local - Moss Lab/ACC/2024_10_29 (1) - complete/test1/2024_10_29_m0027_00001_.h5';
% imgDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/2024_10_29 (1) - complete/test1/mcor';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/2024_10_29 (1) - complete/test1/MAX_m0027_00002_mcor_.tif'; 
% lastMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/2024_10_29 (1) - complete/test1/MAX_m0027_00054_mcor_.tif';
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/2024_10_29 (1) - complete/test1/RoiSet.zip';
% motionCorrectionAcrossFiles = 1;    % no: 0     yes: 1
% plotSubset = 0;                     % no: 0     yes: 1  ALERT: if yes, need to specify firstFig and lastFig numbers

% % m0031 test 2
% timingFile='/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/20241101_m0034_00002.h5';
% imgDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test2/mcor';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test2/MAX_m0031_00001_mcor.tif'; 
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test2/MAX_m0031_00001_mcor_RoiSet2.zip';
% motionCorrectionAcrossFiles = 1;
% plotSubset = 1;
% firstFig = 1;
% lastFig = 75;

% % m0031 test 7
% timingFile='/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/20241101_m0034_00007.h5';
% imgDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test7/mcor';
% firstMaxIntProjFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test7/MAX_m0031_00001_mcor.tif'; 
% roiFileDir = '/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test7/RoiSet.zip';
% motionCorrectionAcrossFiles = 1;
% plotSubset = 1;
% firstFig = 1;
% lastFig = 30;


%% ScanImage stuff - images (WIP, still need to troubleshoot)

% https://vidriotech.gitlab.io/scanimagetiffreader-matlab/
% Weird things I had to do to make this shit work: open every .mexmaca64 file in the folder
% ".../GitHub/PA_ScanImageAnalysis/si-tiff-reader-arm/+ScanImageTiffReader/private"
% to let Apple know that it is safe to run this code

% import ScanImageTiffReader.ScanImageTiffReader;
% reader=ScanImageTiffReader('/Users/priscilla/Documents/Local - Moss Lab/ACC/20241101/test2/m0031_00001.tif');
% vol=reader.data();
% imshow(vol(:,:,floor(size(vol,3)/2)),[]);
% meta=reader.metadata();
% desc=reader.descriptions();
% disp(meta(1:1000));


%% Pre-processing

% Img files
imgFileDirs = dir(fullfile(imgDir, '*.tif'));
imgFileNames = {imgFileDirs.name}';
numberOfImgs = length(imgFileNames);
firstMaxIntProj = imread(firstMaxIntProjFileDir);
if exist('lastMaxIntProjFileDir','var')
    lastMaxIntProj = imread(lastMaxIntProjFileDir);
end

% Fiji ROI file
rois = ReadImageJROI(roiFileDir);
% vnImageSize is one of the inputs for ROIs2Regions
% for whatever reason, it is a translated version of the image size
vnImageSize=[size(firstMaxIntProj,2),size(firstMaxIntProj,1)];
regions=ROIs2Regions(rois,vnImageSize);
totalNumberOfRois = length(rois);


%% Get timing info from TTLs

if analyzeOdorPulse == 1
    odorDurInSec=odor_dur_in_s;
    baselineWindowInSec = baseline_dur_in_s;
end


%% Motion correction across files

tformPerImg = {};
if motionCorrectionAcrossFiles == 1
    % get OS-appropriate file dir
    if ismac
        firstImgFileDir = strcat(imgFileDirs(1).folder, '/', imgFileDirs(1).name);
    elseif ispc
        firstImgFileDir = strcat(imgFileDirs(1).folder, '\', imgFileDirs(1).name);
    end 

    % read first img
    firstImg = imread(firstImgFileDir);
    tformPerImg{1} = [0 0];

    for file = 2:numberOfImgs
        % get OS-appropriate file dir
        if ismac
            imgToAnalyzeFileDir = strcat(imgFileDirs(file).folder, '/', imgFileDirs(file).name);
        elseif ispc
            imgToAnalyzeFileDir = strcat(imgFileDirs(file).folder, '\', imgFileDirs(file).name);
        end 

        % read next img
        nextImg = imread(imgToAnalyzeFileDir);

        % collect and store registration transformation
        tform = imregtform(nextImg, firstImg, 'translation', optimizer, metric);
        tformPerImg{file} = tform.Translation;

        % % comment these out for speed; run for quality control
        % align images based on registration transformation
        % figure;
        % nextImgRegistered = imwarp(nextImg,tform,'OutputView',imref2d(size(firstImg)));
        % imshowpair(firstImg, nextImgRegistered,'Scaling','joint');
        % 
        % % display translated img
        % translatedImg = imtranslate(nextImg,tform.Translation);
        % figure;
        % imshow(translatedImg);
    end
end


%% Fiji ROIs stuff

% meanInt = mean intensity
meanIntPerRoi = [];

for file = 1:numberOfImgs
    % get OS-appropriate file dir
    if ismac
        imgToAnalyzeFileDir = strcat(imgFileDirs(file).folder, '/', imgFileDirs(file).name);
    elseif ispc
        imgToAnalyzeFileDir = strcat(imgFileDirs(file).folder, '\', imgFileDirs(file).name);
    end 

    % get img file name without extension (stored in "f")
    % ALERT f must start with a letter, not a number!!
    [p,f,e] = fileparts(imgFileNames(file));
    
    % get img info
    imgInfo = imfinfo(imgToAnalyzeFileDir);
    numberOfFrames = length(imgInfo);
    
    % iterate frame by frame (each frame is a time point)
    for frame = 1:numberOfFrames
        imgToAnalyze = imread(imgToAnalyzeFileDir,frame);

        if motionCorrectionAcrossFiles == 1
            imgToAnalyze = imtranslate(imgToAnalyze, tformPerImg{file});
        end
    
        % iterate ROI by ROI
        for roiNumber = 1:length(rois)
            labeledRoi = labelmatrix(regions) == roiNumber;
            labeledRoi = labeledRoi';
            nPixelsInRoi = sum(labeledRoi,'all');
            labeledRoiAsInt16 = int16(labeledRoi);
            maskedImg = labeledRoiAsInt16.*imgToAnalyze;
            % it is safe to sum uint16 variables: https://www.mathworks.com/matlabcentral/answers/5401-matlab-function-mean-returns-the-exact-same-value-for-uint16-and-double-values-not-for-single
            meanIntInRoi = sum(maskedImg,'all')/nPixelsInRoi;
            % store mean fluorescence per frame and roi
            meanIntPerRoi(frame,roiNumber) = meanIntInRoi;
        end
    end

    % store info for all files in a structure
    s.(f{1})=meanIntPerRoi;
end


%% xAxis from data pts to time (s)

% ASSUMPTION: all img files have the same numberOfFrames
imagingTotalDataPts=numberOfFrames;
imagingSampleRate=imagingTotalDataPts/img_dur_in_s;
xAxisInSec=linspace(0,img_dur_in_s,imagingTotalDataPts);


%% CALCULATE dF/F and z-scores in ROIs

% ALERT: some files run fine as is, some need an extra step: "delete last
% instance". Comment/uncomment to switch between modes:

% % delete last instance
% % dF/F = (F - F in first frame) / F in first frame
% fns = fieldnames(s);
% dFPerFile=[];
% for file=1:numberOfImgs
%     fPerFile = s.(fns{file});
%     for roi=1:totalNumberOfRois
%         dFPerFile(:,roi) = (fPerFile(:,roi) - fPerFile(1,roi)) / fPerFile(1,roi);
%     end
%     s_dF.(fns{file})=dFPerFile(1:end-1,:);
% end
% 
% % z-score = (dF/F - mean(dF/F)) / sd(dF/F)
% fns = fieldnames(s);
% zScorePerFile=[];
% for file=1:numberOfImgs
%     for roi=1:totalNumberOfRois
%         zScorePerFile(:,roi) = (dFPerFile(:,roi) - mean(dFPerFile(:,roi))) / std(dFPerFile(:,roi));
%     end
%     s_zS.(fns{file})=zScorePerFile(1:end-1,:);
% end

% do NOT delete last instance
% dF/F = (F - F in first frame) / F in first frame
fns = fieldnames(s);
dFPerFile=[];
for file=1:numberOfImgs
    fPerFile = s.(fns{file});
    for roi=1:totalNumberOfRois
        dFPerFile(:,roi) = (fPerFile(:,roi) - fPerFile(1,roi)) / fPerFile(1,roi);
    end
    s_dF.(fns{file})=dFPerFile(1:end,:);
end

% z-score = (dF/F - mean(dF/F)) / sd(dF/F)
fns = fieldnames(s_dF);
zScorePerFile=[];
for file=1:numberOfImgs
    dFPerFile = s_dF.(fns{file});
    for roi=1:totalNumberOfRois
        zScorePerFile(:,roi) = (dFPerFile(:,roi) - mean(dFPerFile(:,roi),'omitnan')) / std(dFPerFile(:,roi),'omitnan');
    end
    s_zS.(fns{file})=zScorePerFile(1:end,:);
end

% mean z-score in ROI across files
fns = fieldnames(s_zS);
zScorePerFile=[];
for roi=1:totalNumberOfRois
    zSPerROI = [];
    for file=1:numberOfImgs 
        zScorePerFile(:,file) = s_zS.(fns{file})(:,roi);
    end
    mean_zS_PerROI(:,roi) = mean(zScorePerFile,2,'omitnan');
end


%% PLOT Fiji ROIs

% how to transform the roi info into a drawable ellipse:
% ASSUMPTION: the ellipse is never tilted
% vnRectBounds information: 
% [top left corner y, top left corner x, bottom right corner y, bottom right corner x]
% in other words:
% vnRectBounds = [y1, x1, y2, x2] where:
% (x1,y1) is the top left corner
% (x2,y2) is the bottom right corner
% ellipse equation:
% ((x-a)^2)/r1^2 + ((y-b)^2)/r2^2 = 1
% where:
% (a,b) is the center of the ellipse
% r1 is the radius of the ellipse on the x axis
% r2 is the radius of the ellipse on the y axis
% in other words:
% a = (x1 + x2)/2
% b = (y1 + y2)/2
% r1 = (x2-x1)/2
% r2 = (y2-y1)/2

% ROIs over max int proj of first img
fig1 = figure('Name','ROIs over first max int proj');
ax1 = axes('Parent',fig1);
imshow(firstMaxIntProj,[],'Parent', ax1)
hold(ax1,'on');
thetas = linspace(0,2*pi,200);
for roiNumber=1:length(rois)
    ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
    ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
    ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
    ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
    ellipseX = ellipseR1*cos(thetas)+ellipseA;
    ellipseY = ellipseR2*sin(thetas)+ellipseB; 
    plot(ellipseX,ellipseY,'Parent',ax1);
end
hold(ax1,'off');

% ROIs over last frame of last img
fig2 = figure('Name','ROIs over last frame of last img');
ax2 = axes('Parent',fig2);
% imgToPlot = uint16(imgToAnalyze);
imshow(imgToAnalyze,[],'Parent', ax2);
hold(ax2,'on');
thetas = linspace(0,2*pi,200);
for roiNumber=1:length(rois)
% for roiNumber=[1 2 3 5 6 8 11 12 13 14]
    ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
    ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
    ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
    ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
    ellipseX = ellipseR1*cos(thetas)+ellipseA;
    ellipseY = ellipseR2*sin(thetas)+ellipseB; 
    plot(ellipseX,ellipseY,'Parent',ax2);
end
hold(ax2,'off');

% % ROIs over max int proj of last img
% % ALERT: I am not adjusting the position of this fig!
% if exist('lastMaxIntProjFileDir','var')
%     fig3 = figure('Name','ROIs over last max int proj');
%     ax3 = axes('Parent',fig3);
%     imshow(lastMaxIntProj,'Parent', ax3);
%     hold(ax3,'on');
%     thetas = linspace(0,2*pi,200);
%     for roiNumber=1:length(rois)
%         ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
%         ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
%         ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
%         ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
%         ellipseX = ellipseR1*cos(thetas)+ellipseA;
%         ellipseY = ellipseR2*sin(thetas)+ellipseB; 
%         plot(ellipseX,ellipseY,'Parent',ax3);
%     end
%     hold(ax3,'off');
% end

% % plot ROIs as colorful blobs
% labeledRois = labelmatrix(regions);
% labeledRois = labeledRois';
% labeledRois_RGB = label2rgb(labeledRois);
% figure 
% imshow(labeledRois_RGB) 
% 
% % plot a single ROI
% L_sub = labelmatrix(regions) == 1;
% RGB_sub = label2rgb(L_sub');
% figure 
% imshow(RGB_sub) 


%% PLOT data in ROIs

% set default firstFig and lastFig boundaries in case user does NOT want a
% custom subset
if plotSubset == 0
    firstFig = 1;
    lastFig = numberOfImgs;
end
firstFigName = fns{firstFig};
lastFigName = fns{lastFig};

% dF/F
for roi=1:totalNumberOfRois
% for roi=[1 2 3 5 6 8 11 12 13 14]
    figure('Name',strcat(firstFigName, '_to_', lastFigName, '_roi_', num2str(roi), '_dF'))
    hold on;
    for file=firstFig:lastFig
    % for file=1:numberOfImgs
        plot(xAxisInSec',s_dF.(fns{file})(:,roi));
        if analyzeOdorPulse == 1
            xline(baselineWindowInSec);
            xline(baselineWindowInSec+odorDurInSec);
        end
    end
    hold off;
    axis([0 xmax -5 ymax])
    xlabel('Time (s)')
    ylabel('dF/F')
end

% z-score
for roi=1:totalNumberOfRois
% for roi=[1 2 4]
    figure('Name',strcat(firstFigName, '_to_', lastFigName, '_roi_', num2str(roi), '_zScore'))
    hold on;
    for file=firstFig:lastFig
        plot(xAxisInSec',s_zS.(fns{file})(:,roi));
        if analyzeOdorPulse == 1
            xline(baseline_dur_in_s);
            xline(baseline_dur_in_s+odor_dur_in_s);
        end
    end
    plot(xAxisInSec',mean_zS_PerROI(:,roi),'Color','k','LineWidth',1)
    hold off;
    axis([0 xmax -5 ymax])
    xlabel('Time (s)')
    ylabel('z-score')
end
    

%% ARCHIVE - outdated code I'm hoarding

% for roiNumber = 1:length(rois)
%     labeledRoi = labelmatrix(regions) == roiNumber;
%     labeledRoi = labeledRoi';
%     nPixelsInRoi = sum(labeledRoi,'all');
%     labeledRoiAsUint16 = uint16(labeledRoi);
%     maskedImg = labeledRoiAsUint16.*firstMaxIntProj;
%     figure
%     imshow(maskedImg)
%     for frame = 1:numberOfFrames
%         imgToAnalyze = imread(imgToAnalyzeFileDir,frame);
%         maskedImg = labeledRoiAsUint16.*imgToAnalyze;
%         meanIntInRoi = sum(maskedImg,'all')/nPixelsInRoi;
%         meanIntPerRoi(frame,roiNumber) = meanIntInRoi;
%     end        
% end