A small containerized Tor relay that runs either a public or private obfs4
bridge on port 80. The combination of common port and the obfs4 protocol should
make it difficult for ISPs, universities, employers, or other network censors
to block.

Running an ephemeral public bridge is a one-liner:
```
docker run -d \
           --restart always \
           -v /etc/localtime:/etc/localtime:ro \
           -p 80:80 \
           --name obfs4 \
           gtank/obfs4bridge -f /etc/tor/torrc.public
```
And you're done! Make sure port 80 is accessible on your host and Tor will take
care of telling the bridge authority about your relay.

To persist keys beyond the container's lifetime, including across system
reboots, you'll need to bind mount over tor's data directory:
```
docker run -d \
           --restart always \
           -v /etc/localtime:/etc/localtime:ro \
           -v ~/.tor:/var/lib/tor \
           -p 80:80 \
           --name obfs4bridge \
           gtank/obfs4bridge -f /etc/tor/torrc.public
```

A public bridge helps the most people but carries the risk of being blocked as
more people use it. If you want a stealthier bridge for your own use, you can
opt to run a private bridge.

To run a private bridge, start the container with `-f /etc/tor/torrc.private` instead.

To use your bridge you'll need to dump the bridgeline template. If you've
mounted the data directory at ~/.tor you can read it with:
```
$ cat ~/.tor/pt_state/obfs4_bridgeline.txt
```

You'll see the configuration line at the bottom of the file. Replace the
placeholder values with the IP address of your server, the fingerprint from
`~/.tor/fingerprint`, and port number 80 and it's ready to be used in either
tor itself or TBB.
