function lut=TChere_filter2lut(filter,C)
lut =zeros(size(filter,1),size(filter,2),size(C,2),'single');
for r=1:size(lut,1)
    for c=1:size(lut,2)
        lut(r,c,:)=permute(C'*permute(filter(r,c,:),[3 1 2]),[3 1 2]);
    end
end
end

