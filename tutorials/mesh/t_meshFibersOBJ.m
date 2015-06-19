%% t_meshFibersOBJ
%
%  Shows how to create OBJ fiber files from AFQ fibers.
%
% BW/LMP

%% Download a small set of fibers in a pdb file

remote = 'http://scarlet.stanford.edu/validation/MRI/VISTADATA';
remoteF = 'diffusion/sampleData/fibers/leftArcuateSmall.pdb';
remoteF = fullfile(remote,remoteF);
tmp = [tempname,'.pdb'];
[fgFile, status] = urlwrite(remoteF,tmp);

% Read the fiber groups
fg = fgRead(fgFile);

% Render the Tract FA Profile for the left uncinate
% A small number of triangles (25 is the default).
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg,'subdivs',6);
% mrvNewGraphWin; surf(fSurf.X{1},fSurf.Y{1},fSurf.Z{1},fSurf.C{1})
% mrvNewGraphWin; plot3(FV.vertices(:,1),FV.vertices(:,2),FV.vertices(:,3),'.');

%% Accumulate fascicles into a structure that we can write using objWrite

% The obj structure has one list of vertices and one list of normals.
% It can then have multiple groups of fascicles (e.g., f1, f2, ...)
% But we end up accumulating the vertices from all the fascicles, and when
% we descrive the faces for, say, f2, they have to refer to the vertices
% for f2, not the vertices for f1.  So, we need to add an offset value to
% the faces.
FV.vertices = [];
FV.faces    = [];
N           = [];
% select = 1:10;  % Small for debugging.  Select only some faces.
cnt = 0;
for ff = [1:4:size(fvc)]
    
    % We expertimented with color, and this worked in meshLab but not in
    % brainbrowser
    %
    %     % When we add color, we do it this way by appending RGB to the
    %     % vertex, and dealing with the first case separately
    %     if isempty(FV.vertices)
    %         % FV.vertices = [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)];
    %         FV.vertices = [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)];
    %     else
    %         % Vertices of the triangles defining the fascicle mesh
    %         % FV.vertices = [FV.vertices; [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)]];
    %     end
    
    % Cumulate the vertices
    FV.vertices = [FV.vertices; fvc(ff).vertices];
    
    % Cumulate the normals for each vertex
    [Nx,Ny,Nz] = surfnorm(fSurf.X{ff},fSurf.Y{ff},fSurf.Z{ff});
    tmp =[Nx(:),Ny(:),Nz(:)];
    N = [N ; tmp];
    
    % Add an offset to the faces, to make them consistent with cumulating
    % vertices.
    FV.faces    = [FV.faces; fvc(ff).faces + cnt];
    
    % Update where we are
    cnt = size(FV.vertices,1);

end

%% Format the OBJ data and write them out

OBJ = objFVN(FV,N);

name = '/Users/wandell/Desktop/deleteMe.obj';
objWrite(OBJ,name);


%% END