FROM ruby:2.4.4-alpine

LABEL maintainer="romulo.08g@gmail.com>"

WORKDIR /root

RUN mkdir /immutable

COPY ./root /root

COPY ./ip.json /immutable

COPY ./gc_authentication.json /immutable

RUN bundle install

#Set the firewall type with DO (to digital ocean) or GC (to Google Cloud).
ENV firewall_type ''

#Firewall update per minute (value 0 or less will run only once).
ENV loop_var '0'

#The firewall will open in tcp and udp, define the ports by separating with a comma or type "0" to release all ports.
ENV ports '0'

#DO: The access token.
#GC: The project_id (remember to fill in gc_authentication.json with your json credentials).
ENV acess_key ''

#DO: The firewall name to update.
#GC: Give your firewall a name to be created and updated by the Gatekeeper (WARNING: DO NOT CHANGE).
ENV firewall_name ''

CMD ["ruby", "main/main.rb"]