NPC's will spawn linked to their deployment. When an NPC is killed it will destroy a container of that deployment. 
Models worden bepaald a.d.h.v van de versie tag op de image: deze gaat van v1 tot v3.



TODO:
Er mag maar maximum 1 deployment aanwezig zijn op de cluster. Het pakt altijd de eerste deployment die de API teruggeeft.
Dit wordt nog uitgebreid naar meerder deployments met verschillende labels om verschillende modellen op te roepen. 

TODO: Meerdere deployments en afhankelijk van het model een specifieke versie deployment neerhalen.
BV. Deployment1 heeft nginx:v1 en deployment2 heeft alpine:v2. Dan moet er als een een v1 model neergeschoten wordt een v1 container verwijderd worden.
killContainer hangt van deze variabelen af: - deploymentnaam
											- image versie

Er zijn globale enemy variabelen om de sprite te bepalen. Deze moet in beide bestanden aangepast worden

Stel voor dat er zelf ene lichte image gemaakt wordt. Bv alpine met twee versies om het clean te houden en een consistent omgeving is.