codeunit 50058 "SLGI CSH Purchase Application"
{
    Permissions = tabledata "Purch. Inv. Header" = M,
                  tabledata "Purch. Cr. Memo Hdr." = M;

    procedure PurchaseInvoiceApplication(var PostPurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchApplicPg: Page "SLGI CSH Purch Application";
    begin
        Clear(PurchApplicPg);
        PurchApplicPg.SetVars(PostPurchInvHeader."SLGI CSH Overide Cash App Date");
        if PurchApplicPg.RunModal() = Action::OK then begin
            PurchApplicPg.GetVars(PostPurchInvHeader."SLGI CSH Overide Cash App Date");
            PostPurchInvHeader.Modify();
        end;
    end;

    procedure PurchaseCrMemoApplication(var PostPurchCrHeader: Record "Purch. Cr. Memo Hdr.")
    var
        PurchApplicPg: Page "SLGI CSH Purch Application";
    begin
        Clear(PurchApplicPg);
        PurchApplicPg.SetVars(PostPurchCrHeader."SLGI CSH Overide Cash App Date");
        if PurchApplicPg.RunModal() = Action::OK then begin
            PurchApplicPg.GetVars(PostPurchCrHeader."SLGI CSH Overide Cash App Date");
            PostPurchCrHeader.Modify();
        end;
    end;
}