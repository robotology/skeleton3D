function [ f ] = plot_RF(pos, normal, varargin )
%PLOT_RF Plot RF of a taxel
%   Detailed explanation goes here
%   pos: position vector
%   normal: normal vector
%   varargin{1}: fig
%% Transform and varargin
matT=  [1 0 0 0;
        0 1 0 0;
        0 0 1 0;
        0 0 0 1];
    
newRF = 1;  %Choose the new Receptive Field model by default
thrRF = 0.0;    % threshold of the RF: 0 for the whole, 1 for nothing
SKIN_VERSION = 2;
percRF = 1.0;   % percentage of the RF

if (~isempty(varargin))
    if (length(varargin)>=6)
        fig = varargin{1};
        matT = varargin{2};  
        newRF = varargin{3};
        thrRF = varargin{4};
        SKIN_VERSION = varargin{5};
        percRF = varargin{6};
    elseif (length(varargin)>=5)
        fig = varargin{1};
        matT = varargin{2};  
        newRF = varargin{3};
        thrRF = varargin{4};
        SKIN_VERSION = varargin{5};
    elseif (length(varargin)>=4)
        fig = varargin{1};
        matT = varargin{2};  
        newRF = varargin{3};
        thrRF = varargin{4};
    elseif (length(varargin)>=3)
        fig = varargin{1};
        matT = varargin{2};  
        newRF = varargin{3};
    elseif (length(varargin)>=2)
        fig = varargin{1};
        matT = varargin{2};  
    elseif (length(varargin)>=1)
        fig = varargin{1};        
    end
else
    fig = figure;
end
   
%% Initialize variables.
filename = './ppsTaxelsFiles/taxels1D_45cmRF_skinV2_perfect_l_forearm.ini'
delimiter = {' ','(',')'};
startRow = 8;

%% Read columns of data as strings:
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44]
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


%% Exclude columns with non-numeric cells
I = ~all(cellfun(@(x) (isnumeric(x) || islogical(x)) && ~isnan(x),raw),1); % Find columns with non-numeric cells
raw(:,I) = [];

%% Initialize column outputs.
columnIndices = cumsum(~I);

%% Allocate imported array to column variable names
if ~I(1)
    l_forearm = cell2mat(raw(:, columnIndices(1)));
end

%% Check the RF range
startRow = 5;
endRow = 5;
formatSpec = '%s%s%s%[^\n\r]';
fileID = fopen(filename,'r');
dataRF = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow-1, 'ReturnOnError', false);
fclose(fileID);
RF = repmat({''},length(dataRF{1}),length(dataRF)-1);
for col=1:length(dataRF)-1
    RF(1:length(dataRF{col}),col) = dataRF{col};
end
numericData = NaN(size(dataRF{1},1),size(dataRF,2));

for col=[1,2,3]
    rawRF = dataRF{col};
    for row=1:size(rawRF, 1);
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawRF{row}, regexstr, 'names');
            numbers = result.numbers;
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                RF{row, col} = numbers{1};
            end
        catch me
        end
    end
end
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),RF); % Find non-numeric cells
RF(R) = {NaN}; % Replace non-numeric cells
RFmin = cell2mat(RF(:, 2));
RFmax = percRF*cell2mat(RF(:, 3));


%% PWE generation
numPts = 20;
d = (RFmax-RFmin)/numPts;
% D = -.1:d:.2-d;
% xi = -.1:d/10:.2-d;
D = RFmin+d:d:RFmax;
xi = RFmin+d:d/10:RFmax;
j=1;
for i=1:1
    values(i,1:length(raw)-1) = cell2mat(raw(i,2:length(raw)));
    p(i,1:(length(raw)-1)/2) = values(i,1:(length(raw)-1)/2);
    n(i,1:(length(raw)-1)/2) = values(i,(length(raw)-1)/2+1:(length(raw)-1));
    
    % Remove the component equal to NaN
    pn = p(i,:) + n(i,:);
    idZero = find(pn==0 & p(i,:)==0);
    P(i,1:(length(raw)-1)/2)= p(i,:)./(n(i,:)+p(i,:));
    P(i,idZero) = 0;
    %===================================
    if (any(p(i,:)~=0))
        figureTitle = sprintf('Taxel %ith',l_forearm(i));
        [f(i,:),x] = parzen_estimation(D,P(i,:),4*d,'r',figureTitle,0,[RFmin RFmax]);
    end
end



%% Taxel transformation
taxel_pos = [pos normal];
pos0 = taxel_pos;
for i=1:1
    pos1(i,:) = matT(1:3,4)+matT(1:3,1:3)*taxel_pos(i,1:3)';
    pos0n(i,:)= taxel_pos(i,4:6)+taxel_pos(i,1:3);
    pos1n(i,:)= matT(1:3,4)+matT(1:3,1:3)*pos0n(i,:)';
    taxel_pos(i,1:3) = pos1(i,:)';
    taxel_pos(i,4:6) = pos1n(i,:)' - pos1(i,:)';
end

posOrigin = matT(1:3,4)';

%% Plot whole PPS
figure(fig); hold on
colormap autumn %flag hot gray

for i=1:1
    if (nnz(taxel_pos(i,:)) > 1) % it's not an all-zero row
        plot3(taxel_pos(i,1),taxel_pos(i,2),taxel_pos(i,3),'xb');
    end
end

lNorm = 0.1;
for i=1:1
    if (any(f(i,:)~=0))
        for j=1:1
                if (newRF)
                    h = maximumRF_func([taxel_pos(j,1),taxel_pos(j,2),taxel_pos(j,3)],-sign(j-192.5),-f(i,59:end),[RFmin RFmax],thrRF);
                else
                    h = hist_map3d([taxel_pos(j,1),taxel_pos(j,2),taxel_pos(j,3)],-sign(j-192.5)*x(59:end),-f(i,59:end));
                    % -sign(j-192.5) is to differentiate between lower and
                    % upper portion of forearm (from taxelID 193, the other
                    % part starts) - different orientation
                    % x(59:end) - to plot only the positive part of RF -
                    % dependent on the number of bins 
                    % revertign the signs for the heatmap -f(i,59:end)
                end
                          
                v1 = [taxel_pos(j,1),taxel_pos(j,2),taxel_pos(j,3)-sign(j-192.5)*.05];
                vz = [0 0 -sign(j-192.5)*.05];
                v2 = [taxel_pos(j,4),taxel_pos(j,5),taxel_pos(j,6)];
                n = cross(vz,v2);
                angle(j) = acos(dot(vz,v2)/(norm(vz)*norm(v2)));
                rotate(h,n,angle(j)/pi*180,taxel_pos(j,1:3));
                
                text(taxel_pos(j,1),taxel_pos(j,2),taxel_pos(j,3),int2str(j-1),'Color','r'); 
                h = quiver3(taxel_pos(j,1),taxel_pos(j,2),taxel_pos(j,3),lNorm*taxel_pos(j,4),lNorm*taxel_pos(j,5),lNorm*taxel_pos(j,6));
                set(h, 'Color', 'b', 'LineWidth', 2, 'MaxHeadSize', 4, 'ShowArrowHead', 'on');
        end
    end
end
end

