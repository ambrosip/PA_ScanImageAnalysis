%{ 

protocol:

move .h5 and events.csv files into imgDir
save .zip file with ROIs into imgDir
save avg int projection into imgDir/extra
save avg int projection with flattened ROIs into imgDir/extra

update imgDir and run this script
set saveDir as imgDir/analysis
saveAllFigs

rename files in odor 1 and odor 2 folders to add "a" before date
update user inputs in imagingDataFromFijiROIs_SCRIPT2 and run
saveFigsAndWorkspace

plot_all_ROIs
saveAllFigs

clear all
close all

%}

%% USER INPUT - IMAGE DIR

expDir = '/Users/priscilla/Documents/Local - Moss Lab/20250528/exp3';
imgDir = fullfile(expDir,'processed','mcor');
% rawImgDir = [];     % use rawImgDir = [] if raw img is not available
rawImgDir = fullfile(expDir,'raw');
saveDir = fullfile(expDir,'analysis');

% acquisition parameters - you need to provide frame rate if you're
% not providing rawImgDir. This number will get overwritten if you provide
% rawImgDir
frame_rate_hz = 12.86;


%% USER INPUT - OLFACTOMETER 

% identify file directory
% olfactometer_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250321 partial/Behavior/2025_03_21-14_05_50/2 odor passive delivery_scope-1-Bilateral-CH1/2 odor passive delivery_scope-1-2025_03_21-14_05_50-Events.csv';
% olfactometer_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/Behavior/2025_03_03-14_38_17/2 odor passive delivery_scope-Bilateral-CH1/2 odor passive delivery_scope-2025_03_03-14_38_17-Events.csv';

% label relevant events
trial_start = "Output 1";
odor1_start = "Odor I 01 - eugenol,Output 4";
odor2_start = "Odor I 02 - methyl salicylate,Output 4";

% events raster plot viz
xMinInSec = 0;
xMaxInSec = inf;
yMinForRaster = 0;
yMaxForRaster = 4;


%% USER INPUT - SCOPE H5

% identify file directory (not needed if you move file to imgDir)
% h5_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250321 partial/20250321__00001.h5';
% h5_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/20250303_00006.h5';

% label relevant events
% ALERT: ImagingWindow was used as trial_start in some files and as
% imaging_window in other files!
trial_start_dataset = '/ImagingWindow';
odor_dataset = '/OdorDelivery';


%% USER INPUT - SCOPE IMGS

% identify file directory (not needed if you move file to imgDir)
% imgs_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250321 partial/odor delivery 1 (1 to 62)';
% imgs_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)';


%% PRE-PROCESS - FIND olfactometer csv and scope h5 files

imgs_file_dir = imgDir;

olfactometer_file_name = dir(fullfile(expDir, '*.csv')).name;
olfactometer_file_dir = fullfile(expDir,olfactometer_file_name);

h5_file_name = dir(fullfile(expDir, '*.h5')).name;
h5_file_dir = fullfile(expDir,h5_file_name);

roi_file_name = dir(fullfile(expDir, '*.zip')).name;
roi_file_dir = fullfile(expDir,roi_file_name);


%% PRE-PROCESS - FIND frame rate and number of frames using ScanImage

% if user set "rawImgDir = []", we can still find the number of frames of
% each image, but we can't find the frame rate (ie user needs to specify
% frame rate)
if isempty(rawImgDir)

    % alternative way of getting numberOfFrames
    % ASSUMPTION ALERT: all figures in folder  have the same number of frames
    imgFileDirs = dir(fullfile(imgDir, '*.tif'));
    imgToAnalyzeFileDir = fullfile(imgFileDirs(1).folder, imgFileDirs(1).name);
    imgInfo = imfinfo(imgToAnalyzeFileDir);
    numberOfFrames = length(imgInfo);
    frames_per_img = numberOfFrames;

else

    % use scanimage metadata to get frame rate and number of frames

    % https://vidriotech.gitlab.io/scanimagetiffreader-matlab/
    % Weird things I had to do to make this shit work: open every .mexmaca64 file in the folder
    % ".../GitHub/PA_ScanImageAnalysis/si-tiff-reader-arm/+ScanImageTiffReader/private"
    % to let Apple know that it is safe to run this code
    
    % get complete file dir and name for first image in rawImgDir
    % ASSUMPTION ALERT: all figures in folder rawImgDir have the same number of frames
    % and frame rate
    rawImgFileDirs = dir(fullfile(rawImgDir, '*.tif'));
    rawImgFileNames = {rawImgFileDirs.name}';
    rawImgToAnalyzeFileDir = fullfile(rawImgFileDirs(1).folder, rawImgFileDirs(1).name);
    
    % use ScanImageTiffReader to extract metadata 
    import ScanImageTiffReader.ScanImageTiffReader;
    reader=ScanImageTiffReader(rawImgToAnalyzeFileDir);
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
    numberOfFrames = framesPerSlice;
    frames_per_img = framesPerSlice;
    frame_rate_hz = scanFrameRate;

end


%% MAIN - OLFACTOMETER

% get today's date for naming output files
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% load csv data and speficy text data as string instead of char
olfactometer_file = readtable(olfactometer_file_dir, TextType="string");

% get relevant info fom file name
fileName = olfactometer_file_dir(end-29:end-4);

% find rows with relevant events
trial_start_rows = matches(olfactometer_file.Events,trial_start);
odor1_start_rows = matches(olfactometer_file.Events,odor1_start);
odor2_start_rows = matches(olfactometer_file.Events,odor2_start);

% x axis in minutes
x_minutes = table2array(olfactometer_file(:,1))/60/1000;

% timestamps for relevant events
trial_start_ts = x_minutes(trial_start_rows);
odor1_start_ts = x_minutes(odor1_start_rows);
odor2_start_ts = x_minutes(odor2_start_rows);


%% CONCATENATING AND LABELING OLFACTOMETER ODOR TIMESTAMPS

% copy olfactometer timestamps into a different variable
odor1_start_ts_labeled = odor1_start_ts;
odor2_start_ts_labeled = odor2_start_ts;

% add odor identity to second column
odor1_start_ts_labeled(:,2) = 1;
odor2_start_ts_labeled(:,2) = 2;

% concatenate two odor lists
odor_start_ts_labeled = [odor1_start_ts_labeled; odor2_start_ts_labeled];

% sort odors lists based on timestamps
odor_start_ts_labeled = sortrows(odor_start_ts_labeled);


%% MIXING OLFACTOMETER AND SCOPE IMG DATA

% get all tif file names in dir
imgFileDirs = dir(fullfile(imgs_file_dir, '*.tif'));
imgFileNames = {imgFileDirs.name}';
numberOfImgs = length(imgFileNames);

% get acquisition # from img file name
% ASSUMPTION: all files name are in the format "YYMMDD_mNNNN_AAAAA_..."
% where N is mouse number and A is acquisition number
acq_list = [];
for file=1:numberOfImgs
    img_file_name = cell2mat(imgFileNames(file));
    % if I added a letter to the file name already, get acq number from the
    % correct location in the file name
    if img_file_name(1) == 'a'
        acq_list = [acq_list; img_file_name(17:21)];
    else
        acq_list = [acq_list; img_file_name(16:20)];
    end
end

% add 3rd column with acquisition number for sorting img files later
% I need this semi-complicated method of assigning acquisition numbers to
% sequential odor deliveries because sometimes the scope acquires extra
% files, so the acquisition numbers are not neatly ordered "1,2,3..."
% but often have gaps, like "1,3,4..."
% ALERT: for this method to work, I need to manually remove single frame
% files from the directory. TO DO: automate removal of single frame files
% (you can do this based on the size of the file)
% before doing this, drop the last odor_start_ts in case you have a
% mismatch in the size of odor_start_ts_labeled and acq_list
if size(odor_start_ts_labeled,1) > size(acq_list,1)
    % odor_start_ts_labeled = odor_start_ts_labeled(1:end-1,:);
    odor_start_ts_labeled = odor_start_ts_labeled(1:size(acq_list,1),:);
end
odor_start_ts_labeled(:,3) = str2num(acq_list);

% display as table with headers
array2table(odor_start_ts_labeled,'VariableNames',{'min','odor','acq'})

% get list of acq for each odor
acq_odor1 = odor_start_ts_labeled(odor_start_ts_labeled(:,2) == 1,3);
acq_odor2 = odor_start_ts_labeled(odor_start_ts_labeled(:,2) == 2,3);


%% COPY IMG FILES BASED ON ODOR

% make directories for copying files
destination_dir1 = fullfile(imgs_file_dir,'odor 1');
destination_dir2 = fullfile(imgs_file_dir,'odor 2');

% check that the directories do not exist
if not(isfolder(destination_dir1))

    % create the directories
    mkdir(destination_dir1);
    mkdir(destination_dir2);
    
    % copy img files into odor-segregated folders
    for file=1:numberOfImgs
        img_file_name = cell2mat(imgFileNames(file));
        % if I added a letter to the file name already, get acq number from the
        % correct location in the file name
        if img_file_name(1) == 'a'
            acq_number = str2num(img_file_name(17:21));
        else
            acq_number = str2num(img_file_name(16:20));
        end
        source_file = fullfile(imgFileDirs(file).folder, imgFileDirs(file).name);
        if ismember(acq_number,acq_odor1)
            copyfile(source_file,destination_dir1);
        elseif ismember(acq_number,acq_odor2)
            copyfile(source_file,destination_dir2);
        end
    end 
end


%% MAIN - SCOPE H5

% get today's date for naming output files
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% get relevant data
total_data_points = h5info(h5_file_dir, trial_start_dataset).Dataspace.Size;
samplerate = h5info(h5_file_dir).Attributes.Value;
trial_start_TTL = h5read(h5_file_dir, trial_start_dataset);
odor_TTL = h5read(h5_file_dir, odor_dataset);

% get relevant info fom file name
fileName_h5 = h5_file_dir(end-16:end);

% x axis in minutes
x_data_points_h5 = 1:total_data_points;
x_minutes_h5 = x_data_points_h5/samplerate/60;

% find onset of TTL pulses
[trial_pks,trial_locs]=findpeaks(diff(trial_start_TTL),'MinPeakHeight',2);
[odor_pks,odor_locs]=findpeaks(diff(odor_TTL),'MinPeakHeight',2);

% find offset of odor TTL pulse
[odor_end_pks,odor_end_locs]=findpeaks(-diff(odor_TTL),'MinPeakHeight',2);

% adjust timing of locs (to account for diff function used to find peaks)
trial_locs = trial_locs + 1;
odor_locs = odor_locs + 1;
odor_end_locs = odor_end_locs + 1;

% convert locs from data points to minutes
trial_locs = trial_locs/samplerate/60;
odor_locs = odor_locs/samplerate/60;
odor_end_locs = odor_end_locs/samplerate/60;


%% FIG 1 - OLFACTOMETER RASTER

fig1 = figure('name', strcat(fileName, '_', analysisDate, ' - raster'));
plot(trial_start_ts,1,'|','Color','k','LineWidth',1)
hold on;
plot(odor1_start_ts,2,'|','Color','b','LineWidth',1)
plot(odor2_start_ts,3,'|','Color','r','LineWidth',1)
hold off;
axis([xMinInSec xMaxInSec yMinForRaster yMaxForRaster])
yticks([]);
xticks([0,30]);
xlabel('Time (min)');
set(fig1, 'Position', [0 0 500 100])    % x y width height


%% FIG 2 - SCOPE H5 Time-series and peaks

fig2 = figure('name', strcat(fileName_h5, '_', analysisDate, ' - scope events'));
plot(x_minutes_h5,trial_start_TTL, 'Color','k')
hold on;
plot(trial_locs,trial_pks,'o','Color','k')
plot(x_minutes_h5,odor_TTL, 'Color','m')
% plot(odor_locs,trial_pks,'o','Color','m')
plot(odor_locs,odor_pks,'o','Color','m')
plot(odor_end_locs,odor_end_pks,'*','Color','y')
hold off


%% FIG 3 - OLFACTOMETER vs SCOPE raster

fig3 = figure('name', strcat(fileName_h5, '_', analysisDate, ' - raster comparison'));
% olfactometer
    plot(trial_start_ts,1,'|','Color','k','LineWidth',1)
    hold on;
    plot(odor1_start_ts,2,'|','Color','b','LineWidth',1)
    plot(odor2_start_ts,3,'|','Color','r','LineWidth',1)
% scope
    xline(trial_locs,'Color','k')
    xline(odor_locs,'Color','m')
hold off;
axis([xMinInSec xMaxInSec yMinForRaster yMaxForRaster])
yticks([]);
xticks([0,30]);
xlabel('Time (min)');
set(fig3, 'Position', [0 0 1000 100])    % x y width height


%% 

% test if you missed the first trial peak, causing the size of odor_locs to
% be larger than the size of trial_locs
if size(trial_locs,1) < size(odor_locs,1)
    % drop off the first odor_locs and the first odor_end_locs
    odor_locs = odor_locs(2:end);
    odor_end_locs = odor_end_locs(2:end);
end
baseline_dur_in_s = mean((odor_locs - trial_locs)*60);
img_dur_in_s = frames_per_img / frame_rate_hz;
baseline_dur_in_frames = baseline_dur_in_s * frame_rate_hz;
odor_dur_in_s = mean((odor_end_locs - odor_locs)*60);
odor_dur_in_frames = odor_dur_in_s * frame_rate_hz;


