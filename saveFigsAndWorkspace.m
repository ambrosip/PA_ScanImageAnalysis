%{
saveFigsAndWorkspace

saves all figures in destination folder set by saveDir (remember to
add single quotes around the directory) and uses the figure name as
file name.

EX:
saveFigsAndWorkspace('R:\Basic_Sciences\Phys\Lerner_Lab_tnl2633\Priscilla\Data
summaries\2019-04-29')
%}

FigList = findobj(allchild(0), 'flat', 'Type', 'figure');

% save all open figs
for iFig = 1:length(FigList)
  FigHandle = FigList(iFig);
  FigName = FigList(iFig).Name;
  set(0, 'CurrentFigure', FigHandle);

  % % I don't know why but I had to change '.tiff' to '.tif' on Nov 6
  % % 2024 because MATLAB refused to run the code. I think the culprit is
  % % the ezcalcium code
  % saveas(FigHandle,fullfile(FolderName, [FigName '.tif']));
  
  % forces matlab to save fig as a vector
  FigHandle.Renderer = 'painters';
  
  % actually saves a vector file
  saveas(FigHandle,fullfile(saveDir, [FigName '.svg']));
end

disp('I saved the figs')
close all

% save workspace variables
[~,odorAnalyzed] = fileparts(imgDir);
matFileName = strcat(analysisDate, '_', odorAnalyzed, '_', firstFigName, '_to_', lastFigName);
save(fullfile(saveDir,matFileName));     

disp('I saved the mat file')

