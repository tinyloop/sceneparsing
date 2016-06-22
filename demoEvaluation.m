% This script demos evaluation on all the prediction maps in pathPred
% make sure you have corresponding ground truth label maps in pathLab
close all; clc; clear;

%% Options and paths
VERBOSE = 0;    % to show individual image results, set it to 1
% path to image(.jpg), prediction(.png) and annotation(.png)
pathImg = fullfile('sampleData', 'images');
%pathPred = fullfile('sampleData', 'predictions');
%pathAnno = fullfile('sampleData', 'annotations');
pathPred = '/data/vision/oliva/scenedataset/segmentation_hang/SceneSegmentation/object150/visualization_test/';
pathAnno = '/data/vision/oliva/scenedataset/segmentation_hang/ADE20K/trainval/anno384_mirror/';

addpath(genpath('evaluationCode/'));
addpath(genpath('visualizationCode'));

% number of object classes: 150
numClass = 150; 
% load class names
load('objectName150.mat');
% load pre-defined colors 
load('color150.mat');

%% Evaluation
% initialize statistics
cnt=0;
area_intersection = double.empty;
area_union = double.empty;

% main loop
filesPred = dir(fullfile(pathPred, '*.png'));
for i = 1: numel(filesPred)
    % check file existence
    filePred = fullfile(pathPred, filesPred(i).name);
    fileLab = fullfile(pathAnno, filesPred(i).name);
    if ~exist(fileLab, 'file')
        fprintf('Label file [%s] does not exist!\n', fileLab); continue;
    end
    
    % read in prediction and label
    imPred = imread(filePred);
    imAnno = imread(fileLab);
    
    % check image size
    if size(imPred, 3) ~= 1
        fprintf('Label image [%s] should be a gray-scale image!\n', fileLab); continue;
    end
    if size(imPred)~=size(imAnno)
        fprintf('Label image [%s] should be the same size as label image!\n', fileLab); continue;
    end
    
    % compute IoU
    cnt = cnt + 1;
    fprintf('Evaluating %d/%d...\n', cnt, numel(filesPred));
    [area_intersection(:,cnt), area_union(:,cnt)] = intersectionAndUnion(imPred, imAnno, numClass);

    % Verbose: show indivudual image results
    if (VERBOSE)
        % read image
        fileImg = fullfile(pathImg, strrep(filesPred(i).name, '.png', '.jpg'));
        im = imread(fileImg);
        
        % compute pixel-wise accuracy
        [pixel_accuracy, ~, ~]= pixelAccuracy(imPred, imAnno);
        fprintf('[%s] Pixel-wise accuracy: %2.2f%%\n', fileImg, pixel_accuracy*100.);
        
        % plot result
        plotResult(im, imPred, imAnno, objectNames, colors, fileImg);
        waitforbuttonpress;
    end   
end

%% Summary
IoU = sum(area_intersection,2)./sum(eps+area_union,2);
mean_IoU = mean(IoU);

fprintf('==== Summary IoU ====\n');
for i = 1:numClass
    fprintf('%3d %16s: %.4f\n', i, objectNames{i}, IoU(i));
end
fprintf('Mean IoU over %d classes: %.4f\n', numClass, mean_IoU);