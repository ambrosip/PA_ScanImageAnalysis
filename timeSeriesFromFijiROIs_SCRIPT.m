%{ 
DOCUMENTATION
Created: 2025 04 19
Last edited on: 2025 04 19
Works? Maybe
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

sessionDir = '/Users/priscilla/Documents/Local - Moss Lab/20250409/DA wash in 3';

filter = 1;
span = 50;
plotSubset = 0;
photobleachingWindowInSec = 2;
baseline_dur_in_s = 5;
ymax = 10; % z-score
frame_rate_hz = 1;


%% Pre-processing - get directory of all relevant files

analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% saveDir
saveDir = fullfile(sessionDir, 'Processed', 'Matlab', analysisDate);

% check if saveDir already exists
if not(isfolder(saveDir))
    % create the directory
    mkdir(saveDir);
end

% Raw Imgs files
rawImgDirs = dir(fullfile(sessionDir, 'Raw', '*.tif'));
rawImgNames = {rawImgDirs.name}';
rawImgFolders = {rawImgDirs.folder}';
% ALERT: only analyzing first raw file - ASSUMPTION that all files have the
% same number of frames and frame rate
rawImgToAnalyzeDir = fullfile(rawImgFolders{1}, rawImgNames{1});
rawImgToAnalyze = imread(rawImgToAnalyzeDir);

% Motion Corrected Img files (mcor = motion corrected)
mcorFileDirs = dir(fullfile(sessionDir, 'Processed', 'Mcor', '*.tif'));
mcorFileNames = {mcorFileDirs.name}';
mcorFileFolders = {mcorFileDirs.folder}';
mcor_numberOf = length(mcorFileNames);
    % Add "a" to start of mcor file names if they don't already have it
    % why? because we will use the file name to build a structure later and
    % matlab will refuse to do it if the file name starts with a number
    for file=1:mcor_numberOf
        if mcorFileNames{file}(1)~='a'
            newName = fullfile(mcorFileFolders{file}, strcat('a', mcorFileNames{file}));
            oldName = fullfile(mcorFileFolders{file}, mcorFileNames{file});
            movefile(oldName, newName);
        end
    end
    % Re-adjust the mcorFileDirs etc...
    mcorFileDirs = dir(fullfile(sessionDir, 'Processed', 'Mcor', '*.tif'));
    mcorFileNames = {mcorFileDirs.name}';
    mcorFileFolders = {mcorFileDirs.folder}';
% quality control of user input
mcorImgToAnalyzeDir = fullfile(mcorFileFolders{1}, mcorFileNames{1});
mcorImgToAnalyze = imread(mcorImgToAnalyzeDir);
if size(mcorImgToAnalyze) == size(rawImgToAnalyze)
    disp('mcor and raw imgs match in size')
else
    disp('WARNING: mcor and raw imgs DO NOT match in size')
end

% Fiji Avg Intensity Projection files (zProj = z Projection)
zProjFileDirs = dir(fullfile(sessionDir, 'Processed', 'Fiji', '*.tif'));
zProjFileNames = {zProjFileDirs.name}';
zProjFileFolders = {zProjFileDirs.folder}';
zProj_numberOf = length(zProjFileNames);
zProjFileToAnalyzeDir = fullfile(zProjFileFolders{1}, zProjFileNames{1});
zProjFileToAnalyze = imread(zProjFileToAnalyzeDir);
% quality control of user input
if size(zProjFileToAnalyze) == size(mcorImgToAnalyze)
    disp('zProj and mcor imgs match in size')
else
    disp('WARNING: zProj and mcor imgs DO NOT match in size')
end

% Fiji ROI file (roi = regions of interest)
roisFileDirs = dir(fullfile(sessionDir, 'Processed', 'Fiji', '*.zip'));
roisFileNames = {roisFileDirs.name}';
roisFileFolders = {roisFileDirs.folder}';
% ALERT: only analyzing first roi file
roisFileToAnalyze = fullfile(roisFileFolders{1}, roisFileNames{1});
rois = ReadImageJROI(roisFileToAnalyze);
% vnImageSize is one of the inputs for ROIs2Regions
% for whatever reason, it is a translated version of the image size
vnImageSize=[size(zProjFileToAnalyze,2),size(zProjFileToAnalyze,1)];
regions=ROIs2Regions(rois,vnImageSize);
rois_numberOf = length(rois);


%% Pre-processing - get number of frames per img (and frame rate if raw imgs are available)

% if there are no raw files available, I can still find the number of frames of
% each image, but I can't find the frame rate (ie user needs to specify
% frame rate)
if isempty(rawImgDirs)
    % get numberOfFrames from mcor img
    % ASSUMPTION ALERT: all mcor imgs have the same number of frames
    imgInfo = imfinfo(mcorImgToAnalyze);
    frames_per_img = length(imgInfo);
else
    % use ScanImageTiffReader to extract metadata from raw img
    % some extra documentation on this function
    % https://vidriotech.gitlab.io/scanimagetiffreader-matlab/
    % Weird things I had to do to make this shit work: open every .mexmaca64 file in the folder
    % ".../GitHub/PA_ScanImageAnalysis/si-tiff-reader-arm/+ScanImageTiffReader/private"
    % to let Apple know that it is safe to run this code
    import ScanImageTiffReader.ScanImageTiffReader;
    reader=ScanImageTiffReader(rawImgToAnalyzeDir);
    vol=reader.data();
    meta=reader.metadata();
    
    % variables I care about from the metadata and what they look like:
    % SI.hStackManager.framesPerSlice = 360
    % SI.hRoiManager.scanFrameRate = 27.22874089533803
    
    % helpful commands to remember:
    % imshow(vol(:,:,floor(size(vol,3)/2)),[]);
    % disp(meta(1:1000));
    % desc=reader.descriptions();
    
    % extract variables I care about from metadata
    % since the values are stored in a huge cell of characters, I have to do some
    % extra work to get them. First, I need to extract the characters between
    % the string right before the number and the next line. Then, I need to
    % take the value out of its cell format using the curly brackets. Finally,
    % I convert the string into a number
    % ALERT this only works with the raw images, not with the motion corrected
    % ones
    framesPerSlice = extractBetween(meta,"SI.hStackManager.framesPerSlice = ",newline);
    framesPerSlice = str2double(framesPerSlice{1});
    scanFrameRate = extractBetween(meta,"SI.hRoiManager.scanFrameRate = ",newline);
    scanFrameRate = str2double(scanFrameRate{1});

    % store variables in different names cuz I'm too lazy to change the whole
    % code right now
    frames_per_img = framesPerSlice;
    frame_rate_hz = scanFrameRate;
end


%% Fiji ROIs stuff

% meanInt = mean intensity
meanIntPerRoi = [];

for file = 1:mcor_numberOf

    % get OS-appropriate file dir
    imgToAnalyzeFileDir = fullfile(mcorFileDirs(file).folder, mcorFileDirs(file).name);

    % get img file name without extension (stored in "f")
    % ALERT f must start with a letter, not a number - for building
    % structure later
    [p,f,e] = fileparts(mcorFileNames(file));
    
    % get img info
    imgInfo = imfinfo(imgToAnalyzeFileDir);
    frames_per_img = length(imgInfo);
    
    % iterate frame by frame (each frame is a time point)
    for frame = 1:frames_per_img
        imgToAnalyze = imread(imgToAnalyzeFileDir,frame);
    
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
img_dur_in_s = frames_per_img/frame_rate_hz;
xAxisInSec=linspace(0,img_dur_in_s,frames_per_img);


%% CALCULATE dF/F and z-scores in ROIs 

% do NOT delete last instance
% dF/F = (F - mean F in baseline) / mean F in baseline
fns = fieldnames(s);
dFPerFile=[];
for file=1:mcor_numberOf
    fPerFile = s.(fns{file});
    % check if we need to delete the first few seconds of the data because of photobleaching
    if exist('photobleachingWindowInSec')
        photobleachingWindowInFrames = ceil(photobleachingWindowInSec * frame_rate_hz);
        fPerFile = fPerFile(photobleachingWindowInFrames:end,:);
        adjustedBaselineInSec = baseline_dur_in_s - photobleachingWindowInSec;
        adjustedBaselineInFrames = adjustedBaselineInSec * frame_rate_hz;
    else
        adjustedBaselineInFrames = baseline_dur_in_s * frame_rate_hz;
    end
    for roi=1:rois_numberOf
        meanBaselineF = mean(fPerFile(1:ceil(adjustedBaselineInFrames),roi),'omitnan');
        dFPerFile(:,roi) = (fPerFile(:,roi) - meanBaselineF) / meanBaselineF;
    end
    s_dF.(fns{file})=dFPerFile(1:end,:);
end

% adjust X axis if you removed the photobleaching window
if exist('photobleachingWindowInSec')
    frames_per_img = size(dFPerFile,1);
    img_dur_in_s = frames_per_img / frame_rate_hz;
    xAxisInSec = linspace(0,img_dur_in_s,frames_per_img);
end

% mean dF/F in ROI across files
fns = fieldnames(s_dF);
dFPerFile=[];
for roi=1:rois_numberOf
    dFPerROI = [];
    for file=1:mcor_numberOf 
        dFPerFile(:,file) = s_dF.(fns{file})(:,roi);
    end
    mean_dF_PerROI(:,roi) = mean(dFPerFile,2,'omitnan');
    if filter == 1
        mean_dF_PerROI_filtered(:,roi) = smooth(mean_dF_PerROI(:,roi),span);
    end
end

% z-score = (dF/F - mean(dF/F) in baseline) / sd(dF/F) in baseline
fns = fieldnames(s_dF);
zScorePerFile=[];
for file=1:mcor_numberOf
    dFPerFile = s_dF.(fns{file});
    for roi=1:rois_numberOf
        meanBaseline_dF = mean(dFPerFile(1:ceil(adjustedBaselineInFrames),roi),'omitnan');
        sdBaseline_dF = std(dFPerFile(1:ceil(adjustedBaselineInFrames),roi),'omitnan');
        zScorePerFile(:,roi) = (dFPerFile(:,roi) - meanBaseline_dF) / sdBaseline_dF;
    end
    s_zS.(fns{file})=zScorePerFile(1:end,:);
end

% mean z-score in ROI across files
fns = fieldnames(s_zS);
zScorePerFile=[];
for roi=1:rois_numberOf
    zSPerROI = [];
    for file=1:mcor_numberOf 
        zScorePerFile(:,file) = s_zS.(fns{file})(:,roi);
    end
    mean_zS_PerROI(:,roi) = mean(zScorePerFile,2,'omitnan');
    if filter == 1
        mean_zS_PerROI_filtered(:,roi) = smooth(mean_zS_PerROI(:,roi),span);
    end
end


% %% PLOT data in ROIs
% 
% % set default firstFig and lastFig boundaries in case user does NOT want a
% % custom subset
% if plotSubset == 0
%     firstFig = 1;
%     lastFig = mcor_numberOf;
% end
% firstFigName = fns{firstFig};
% lastFigName = fns{lastFig};
% 
% % dF/F
% for roi=1:rois_numberOf
%     figure('Name',strcat(firstFigName, '_to_', lastFigName, '_roi_', num2str(roi), '_dF'))
%     hold on;
%     for file=firstFig:lastFig
%         plot(xAxisInSec',s_dF.(fns{file})(:,roi));
%     end
%     xline(adjustedBaselineInSec);
%     plot(xAxisInSec',mean_dF_PerROI(:,roi),'Color','k','LineWidth',1)   
%     if filter == 1
%         plot(xAxisInSec',mean_dF_PerROI_filtered(:,roi),'Color','r','LineWidth',1)   
%     end
%     hold off;
%     axis([0 inf -inf inf])
%     xlabel('Time (s)')
%     ylabel('dF/F')
% end
% 
% % z-score
% for roi=1:rois_numberOf
%     figure('Name',strcat(firstFigName, '_to_', lastFigName, '_roi_', num2str(roi), '_zScore'))
%     hold on;
%     for file=firstFig:lastFig
%         plot(xAxisInSec',s_zS.(fns{file})(:,roi));
%     end
%     xline(adjustedBaselineInSec);
%     plot(xAxisInSec',mean_zS_PerROI(:,roi),'Color','k','LineWidth',1)
%     if filter == 1
%         plot(xAxisInSec',mean_zS_PerROI_filtered(:,roi),'Color','r','LineWidth',1)   
%     end    
%     hold off;
%     axis([0 inf -inf inf])
%     xlabel('Time (s)')
%     ylabel('z-score')
% end


% %% PLOT Fiji ROIs
% 
% % how to transform the roi info into a drawable ellipse:
% % ASSUMPTION: the ellipse is never tilted
% % vnRectBounds information: 
% % [top left corner y, top left corner x, bottom right corner y, bottom right corner x]
% % in other words:
% % vnRectBounds = [y1, x1, y2, x2] where:
% % (x1,y1) is the top left corner
% % (x2,y2) is the bottom right corner
% % ellipse equation:
% % ((x-a)^2)/r1^2 + ((y-b)^2)/r2^2 = 1
% % where:
% % (a,b) is the center of the ellipse
% % r1 is the radius of the ellipse on the x axis
% % r2 is the radius of the ellipse on the y axis
% % in other words:
% % a = (x1 + x2)/2
% % b = (y1 + y2)/2
% % r1 = (x2-x1)/2
% % r2 = (y2-y1)/2
% 
% % ROIs over max int proj with flattened ROIs
% fig1 = figure('Name',strcat(firstFigName, '_to_', lastFigName, '_ROIs over first max int proj'));
% ax1 = axes('Parent',fig1);
% imshow(zProjFileToAnalyze,[],'Parent', ax1)
% hold(ax1,'on');
% thetas = linspace(0,2*pi,200);
% for roiNumber=1:length(rois)
%     ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
%     ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
%     ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
%     ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
%     ellipseX = ellipseR1*cos(thetas)+ellipseA;
%     ellipseY = ellipseR2*sin(thetas)+ellipseB; 
%     plot(ellipseX,ellipseY,'Parent',ax1);
% end
% hold(ax1,'off');
% 
% % % ROIs over last frame of last img
% % fig2 = figure('Name',strcat(firstFigName, '_to_', lastFigName, '_ROIs over last frame of last img'));
% % ax2 = axes('Parent',fig2);
% % % imgToPlot = uint16(imgToAnalyze);
% % imshow(imgToAnalyze,[],'Parent', ax2);
% % hold(ax2,'on');
% % thetas = linspace(0,2*pi,200);
% % for roiNumber=1:length(rois)
% % % for roiNumber=[1 2 3 5 6 8 11 12 13 14]
% %     ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
% %     ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
% %     ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
% %     ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
% %     ellipseX = ellipseR1*cos(thetas)+ellipseA;
% %     ellipseY = ellipseR2*sin(thetas)+ellipseB; 
% %     plot(ellipseX,ellipseY,'Parent',ax2);
% % end
% % hold(ax2,'off');
% 
% % ROIs over max int proj 
% if zProj_numberOf > 1
%     zProjFileToAnalyzeDir2 = fullfile(zProjFileFolders{2}, zProjFileNames{2});
%     zProjFileToAnalyze2 = imread(zProjFileToAnalyzeDir2);
%     fig3 = figure('Name',strcat(firstFigName, '_to_', lastFigName, '_ROIs over second max int proj'));
%     ax3 = axes('Parent',fig3);
%     imshow(imadjust(zProjFileToAnalyze2,[0.5 0.65]),'Parent', ax3);
%     hold(ax3,'on');
%     thetas = linspace(0,2*pi,200);
%     for roiNumber=1:length(rois)
%         ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
%         ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
%         ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
%         ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
%         ellipseX = ellipseR1*cos(thetas)+ellipseA;
%         ellipseY = ellipseR2*sin(thetas)+ellipseB; 
%         plot(ellipseX,ellipseY,'Parent',ax3,'Color','y');
%         text(ellipseA,ellipseB,num2str(roiNumber),'Parent',ax3,'Color','y');
%     end
%     hold(ax3,'off');
% end
% 
% % % plot ROIs as colorful blobs
% % labeledRois = labelmatrix(regions);
% % labeledRois = labeledRois';
% % labeledRois_RGB = label2rgb(labeledRois);
% % figure 
% % imshow(labeledRois_RGB) 
% % 
% % % plot a single ROI
% % L_sub = labelmatrix(regions) == 1;
% % RGB_sub = label2rgb(L_sub');
% % figure 
% % imshow(RGB_sub) 
  

%% save figs and workspace

FigList = findobj(allchild(0), 'flat', 'Type', 'figure');

% save all open figs
for iFig = 1:length(FigList)
  FigHandle = FigList(iFig);
  FigName = FigList(iFig).Name;
  set(0, 'CurrentFigure', FigHandle);
  % forces matlab to save fig as a vector
  FigHandle.Renderer = 'painters';  
  % actually saves a vector file
  saveas(FigHandle,fullfile(saveDir, [FigName '.svg']));
end

disp('I saved the figs')
close all

% set default firstFig and lastFig boundaries in case user does NOT want a
% custom subset
if plotSubset == 0
    firstFig = 1;
    lastFig = mcor_numberOf;
end
firstFigName = fns{firstFig};
lastFigName = fns{lastFig};

% save workspace variables
matFileName = strcat(analysisDate, '_', firstFigName, '_to_', lastFigName);
save(fullfile(saveDir,matFileName));     

disp('I saved the mat file')


%% plot_all_ROIs

nColumns = 2;

xmax = img_dur_in_s - photobleachingWindowInSec;
xmaxScale = xmax;
xminScale = 0;
ymaxScale = ymax/2;
xmin = xminScale;
ymin = -ymaxScale;

% create figure & name it
fig=figure('name', strcat(matFileName, '_niceplot'));
set(gca,'FontName','Arial');
set(gcf,'OuterPosition',[100 100 600 900]);
set(gca,'LineWidth', 0.75);
t = tiledlayout(ceil((size(rois,2))/(nColumns-1)), nColumns);

% plot ROIs
nexttile([ceil((size(rois,2))/(nColumns-1)) 1])
imshow(imadjust(zProjFileToAnalyze,[0.5 0.65]))
hold on
thetas = linspace(0,2*pi,200);
for roiNumber=1:length(rois)
    ellipseR1 = (rois{roiNumber}.vnRectBounds(4) - rois{roiNumber}.vnRectBounds(2))/2;
    ellipseR2 = (rois{roiNumber}.vnRectBounds(3) - rois{roiNumber}.vnRectBounds(1))/2;
    ellipseA = (rois{roiNumber}.vnRectBounds(4) + rois{roiNumber}.vnRectBounds(2))/2;
    ellipseB = (rois{roiNumber}.vnRectBounds(3) + rois{roiNumber}.vnRectBounds(1))/2;
    ellipseX = ellipseR1*cos(thetas)+ellipseA;
    ellipseY = ellipseR2*sin(thetas)+ellipseB; 
    plot(ellipseX,ellipseY,'Color','y');
    text(ellipseA,ellipseB,num2str(roiNumber),'Color','y');
end
hold off

% plotting niceplots of filtered dF/F
for roi=1:rois_numberOf
    nexttile
    hold on;
    plot(xAxisInSec',mean_dF_PerROI_filtered(:,roi),'Color','k')
    xline(adjustedBaselineInSec);
    text(xmaxScale,0,num2str(roi))
    axis([xmin xmaxScale ymin ymaxScale])
    % xlabel('Time (s)')
    % ylabel('dF/F')
    % ylabel(num2str(roi))
        
    % remove x and y labels from all ROIs
    xticklabels([]);
    yticklabels([]);
    
    % add scale bar to last plot
    if roi == size(rois,2)
        line([xmaxScale-60*(xmaxScale-xminScale)/xmaxScale,xmaxScale],[ymin,ymin],'Color','k')
        line([xmaxScale,xmaxScale],[ymin,ymin+1],'Color','k')
        text(xmaxScale-(xmaxScale-xminScale),ymin+((ymaxScale-ymin)/xmaxScale),strcat(num2str((xmaxScale-xminScale)/xmaxScale)," min"))
        text(xmaxScale-(xmaxScale-xminScale),ymin+1,strcat(num2str(1)," dF/F"))
    end
    
    set(findall(gcf,'-property','FontSize'),'FontSize',9)
    hold off;    
    set(gca,'Visible','off');
end

title(t,matFileName,'Interpreter', 'none');
t.TileSpacing = 'compact';
t.Padding = 'compact';