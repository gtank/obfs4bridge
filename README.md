There's an image built from this on DockerHub ([gtank/obfs4bridge](https://hub.docker.com/r/gtank/obfs4bridge/)) that I'll use in my examples, but I recommend you build and use your own if you can. To retrieve the container just run `docker pull gtank/obfs4bridge`.

### Configuration

You'll notice that the Dockerfile copies two pre-written torrc (config files) into the container. The most important one is the public bridge config, `torrc.public`, which I've copied below with comments for each line:

```
# Minimal tor config for a public obfs4 bridge
# For futher discussion of ORPort settings, see
# https://trac.torproject.org/projects/tor/ticket/7349

SOCKSPort 0                # no local SOCKS proxy
ORPort auto                # attempt to hide ORPort from active probes
ExtORPort auto             # configure ExtORPort for obfs4proxy
ExitPolicy reject *:*      # no exits allowed
BridgeRelay 1              # relay won't show up in the public consensus
PublishServerDescriptor 1  # publish to the bridge authority
DataDirectory /var/lib/tor # mount this from a data container to save keys

# Some wild guesses at reasonable bandwidth limits.
# You probably want to change these based on your cost of hosting.
RelayBandwidthRate 100KBytes
RelayBandwidthBurst 300KBytes
AccountingMax 250GBytes
AccountingStart month 1 00:00

# use obfs4proxy to provide obfs4 on port 80
ServerTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy
ServerTransportListenAddr obfs4 0.0.0.0:80
```

### Persisting data

When a tor relay runs for the first time, it will generate keys and cache information about the tor network. To maintain the same relay identity across restarts, we have to persist these keys. We'll do this in Docker is with a [data volume](https://docs.docker.com/engine/userguide/containers/dockervolumes/), which we'll name `tor-data`. Run the following command on your Docker host to create it:

```
docker create -v /var/lib/tor --name tor-data gtank/obfs4bridge /bin/true
```

We reuse the tor container (here `gtank/obfs4bridge`) because it will already be cached. You should see a long hex string after the command finishes.

### Running the bridge

With all that out of the way, actually deploying the bridge is a one-liner. Make sure port 80 is open on your docker host, then run the image:

```
docker run -d \
           --restart always \
           -v /etc/localtime:/etc/localtime:ro \
           --volumes-from tor-data \
           -p 80:80 \
           --name obfs4bridge \
           gtank/obfs4bridge tor -f /etc/tor/torrc.public
```

### Running the bridge

After your bridge is running it will take a few hours for it to show up in BridgeDB. You can check it by fingerprint on https://atlas.torproject.org to see the network's view of it. Once it's there, you'll be helping people with censored connections reach the open internet!
