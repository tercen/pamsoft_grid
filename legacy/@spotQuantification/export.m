function export(q, strMethod, fName, xas, sFields)
% function spotQuantification.export(q, strMethod, fName, xas)
switch strMethod
    case 'kinetics'
        exportKinetics(q, fName, xas)
    case 'images'
         nImages  = size(q,3);
         if ~iscell(fName)
             error(['fName should be a cell arry of strings']);
         end
         if length(fName) ~= nImages
             error(['Dimension of quantifcation object array does not agree with number of file names']);
         end
         for i=1:nImages
                 exportImage(q(:,:,i),fName{i});           
         end
    case 'imagesWithSelectedFields'
         nImages  = size(q,3);
         if ~iscell(fName)
             error(['fName should be a cell arry of strings']);
         end
         if ~iscell(sFields) 
             error(['sFields should be a cell array of strings']);
         end
         if length(fName) ~= nImages
             error(['Dimension of quantifcation object array does not agree with number of file names']);
         end
         for i=1:nImages
                 exportImageWithSelectedFields(q(:,:,i),fName{i}, sFields);           
         end
    
    otherwise
        error(['unknown export method: ',strmethod]);
end
