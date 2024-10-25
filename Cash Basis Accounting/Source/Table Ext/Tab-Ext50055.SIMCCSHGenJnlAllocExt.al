tableextension 50055 "SLGI CSH Gen. Jnl. Alloc Ext" extends "Gen. Jnl. Allocation" // 221
{
    fields
    {
        field(70163480; "SLGI CSH Exclude in Cash"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Exclude in Cash';
            Editable = false;
        }
    }
    trigger OnInsert();
    var
        SlgCCSHGenJnLine: Record "Gen. Journal Line";
    begin
        if SlgCCSHGenJnLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.") then
            "SLGI CSH Exclude in Cash" := SlgCCSHGenJnLine."SLGI CSH Exclude In Cash";
    end;

}