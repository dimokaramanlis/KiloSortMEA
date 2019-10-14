function [bininfo] = convertToKsRawBinary(metadata, targetpath)
%CONVERTTOKSRAWBINARY Summary of this function goes here

switch metadata.recording_type
    case 'mcd'
        bininfo = convertMcdToRawBinary(metadata, targetpath);
    case 'h5'
        bininfo = convertMsrdH5ToRawBinary(metadata, targetpath);
end

end

