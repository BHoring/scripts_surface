% Split bihemisphere gifti ("mesh." in CAT12 parlance)
% 
% varargout = GiftiSplitOrMergeHemis('split',meshPath[,lhPath][,meshRegExp])
% meshPath  - path to the bihemispheric mesh file, assumed to be stacked [lh;rh]
% lhPath    - path to lefthemispheric mesh of the resolution as meshPath (optional; will default to CAT12 template if not set or left empty)
% meshRegExp - regular expression included in meshPath that will be replaced by 'lh' and 'rh' after the split (optional, default '^mesh')
% 
% out
% varargout{1} - path to split left hemisphere
% varargout{2} - path to split right hemisphere 
% varargout{3} - left split hemisphere (gifti)
% varargout{4} - right split hemisphere (gifti)
%
% varargout = GiftiSplitOrMergeHemis('merge',meshPath)
% meshPath  - path to the left OR right hemisphere mesh file; file name expected to start with 'lh' or 'rh', from which function extrapolates the respective other
%
% out
% varargout{1} - path to merged hemisphere
% varargout{2} - merged hemisphere (gifti)
%
% Version: 1.1
% Author: Björn Horing, bjoern.horing@gmail.com
% Date: 2021-06-14
%
% Version notes
% 1.x (TODO)
% - add sample bi-/monomesh files
% 1.1
% - function description, comments for Git

function varargout = GiftiSplitOrMergeHemis(action,meshPath,lhPath,meshRegExp)

    switch lower(action)
        
        case 'split'            
            if nargin<3 || isempty(lhPath) % then we assume it's a template bihemi mesh, and default to template left
                lhPath = fullfile(spm('dir'),'toolbox','cat12','templates_surfaces','lh.central.freesurfer.gii');
            end
            if nargin<4
                meshRegExp = '^mesh';
            end
            [varargout{1},varargout{2},varargout{3},varargout{4}] = Split(meshPath,lhPath,meshRegExp);
            
        case 'merge'
            [varargout{1},varargout{2}] = Merge(meshPath);
            
        otherwise
            error('Action %s unknown.',action)
            
    end
    
    
function [meshMergedName,meshMerged] = Merge(meshPath)

    [meshFolder,meshFile,e] = fileparts(meshPath);
    meshFile = [meshFile e]; % grrr

    if isempty(regexp(meshFile,'^[lr]h','ONCE'))
        error('File at %s does not have proper name (must start with lh or rh).',meshPath)
    else
        meshMergedName = regexprep(meshFile,'^[lr]h','mesh');   
        meshMergedName = [meshFolder filesep meshMergedName];
    end
    
    if exist(meshMergedName,'file')
        fprintf('Already merged hemisphere found at %s.\n',meshMergedName); 
        meshMerged = gifti(meshMergedName);
        return;
    end
        
    if ~isempty(regexp(meshFile,'^lh','ONCE'))
        meshL = gifti([meshFolder filesep meshFile]);
        meshR = gifti([meshFolder filesep regexprep(meshFile,'^lh','rh')]);            
    elseif ~isempty(regexp(meshFile,'^rh','ONCE'))
        meshL = gifti([meshFolder filesep regexprep(meshFile,'^rh','lh')]);
        meshR = gifti([meshFolder filesep meshFile]);
    end
    
    fprintf('Merging two hemispheres to %s... ',meshMergedName); 
    meshMerged = meshL;
    meshMerged.vertices = [meshL.vertices;meshR.vertices]; % easy    
    meshMerged.faces = [meshL.faces;meshR.faces+size(meshL.vertices,1)]; % also pretty easy
    if isfield(meshMerged,'cdata')
        meshMerged.cdata = [meshL.cdata;meshR.cdata]; % easy again!
    end
    save(meshMerged,meshMergedName);
    fprintf('done.\n');
    

function [lhSplitName,rhSplitName,lh,rh] = Split(meshPath,lhPath,meshRegExp)

    [meshFolder,meshFile,e] = fileparts(meshPath);
    meshFile = [meshFile e]; % grrr

    if isempty(regexp(meshFile,meshRegExp,'ONCE'))
        error('File at %s does not have proper name (must include ''%s'').',meshPath,meshRegExp)
    else % provide new file names for split content
        lhSplitName = regexprep(meshFile,meshRegExp,'lh');   
        lhSplitName = [meshFolder filesep lhSplitName];
        rhSplitName = regexprep(meshFile,meshRegExp,'rh');   
        rhSplitName = [meshFolder filesep rhSplitName];        
    end

    % load left and right reference meshes for vertex count
    [refPath,refName,refE] = fileparts(lhPath); % since it's only the left hemisphere, extract file name
    lh = gifti(lhPath);
    rh = gifti([refPath filesep regexprep(refName,'^lh','rh') refE]);
    
    mesh = gifti(meshPath);
    
    if size(lh.vertices,1)+size(rh.vertices,1)~=size(mesh.vertices,1)    
        error('Bimesh has %d vertices, sum of monomeshes is %d.',size(mesh.vertices,1),size(lh.vertices,1)+size(rh.vertices,1));
    end

    if isfield(mesh,'cdata')
        lh.cdata = mesh.cdata(1:size(lh.vertices,1));
        rh.cdata = mesh.cdata(size(lh.vertices,1)+1:end);
    end
    
    save(lh,lhSplitName,'Base64Binary');        
    save(rh,rhSplitName,'Base64Binary');        

    fprintf('File %s split successfully to\n\t%s\n\t%s\n',meshFile,lhSplitName,rhSplitName);
    