pageextension 50505 "TFB DS Item List" extends "Item List" //MyTargetPageId
{
    layout
    {
        addafter("Substitutes Exist")
        {


        }

    }


    actions
    {
    }

    views
    {
        addlast
        {


            view(DropShipItems)
            {
                Caption = 'Drop Ship Items';
                Filters = where("Purchasing Code" = const('DS'));
                SharedLayout = true;
            }

        }
    }
}