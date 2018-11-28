/**

Copyright (C) SYSTAP, LLC 2006-2015.  All rights reserved.

Contact:
     SYSTAP, LLC
     2501 Calvert ST NW #106
     Washington, DC 20008
     licenses@systap.com

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/**
 * See <a href="http://wiki.blazegraph.com/wiki/index.php/RDR">RDR</a>
 */

package sample.rdr;

import java.io.InputStream;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.openrdf.model.Statement;
import org.openrdf.query.BindingSet;
import org.openrdf.query.GraphQueryResult;
import org.openrdf.query.TupleQueryResult;
import org.openrdf.rio.RDFFormat;

import com.bigdata.rdf.sail.BigdataSail.Options;
import com.bigdata.rdf.sail.webapp.SD;
import com.bigdata.rdf.sail.webapp.client.IPreparedTupleQuery;
import com.bigdata.rdf.sail.webapp.client.RemoteRepository;
import com.bigdata.rdf.sail.webapp.client.RemoteRepository.AddOp;
import com.bigdata.rdf.sail.webapp.client.RemoteRepositoryManager;

public class SampleBlazegraphRDR {
	
	protected static final Logger log = Logger.getLogger(SampleBlazegraphRDR.class);
	private static final String serviceURL = "http://localhost:9999/bigdata";
	
	public static void main(String[] args) throws Exception  {
	
		final RemoteRepositoryManager repositoryManager = new RemoteRepositoryManager(serviceURL, false /*useLBS*/);
	
		try{	
		
			final String namespace = "namespaceRDR";
			final Properties properties = new Properties();
			properties.setProperty(Options.NAMESPACE, namespace);
			properties.setProperty(Options.STATEMENT_IDENTIFIERS, "true");
			
			if(!namespaceExists(namespace, repositoryManager)){
				log.info(String.format("Create namespace %s...", namespace));
				repositoryManager.createRepository(namespace, properties);
				log.info(String.format("Create namespace %s done", namespace));
			}
			
			final InputStream is = SampleBlazegraphRDR.class.getResourceAsStream("/rdr_test.ttl");
			try{
				repositoryManager.getRepositoryForNamespace(namespace).add(new AddOp(is, RDFFormat.forMIMEType("application/x-turtle-RDR")));
			} finally {
				is.close();
			}
			
			//execute query
			final RemoteRepository r = repositoryManager.getRepositoryForNamespace(namespace);
			final IPreparedTupleQuery query = r.prepareTupleQuery("SELECT ?age ?src WHERE {?bob foaf:name \"Bob\" . <<?bob foaf:age ?age>> dc:source ?src .}");
			final TupleQueryResult result = query.evaluate();
			try {
				while (result.hasNext()) {
					final BindingSet bs = result.next();
					log.info(bs);
				}
			} finally {
				result.close();
			}
		} finally {
			repositoryManager.close();
		}
	}
	
	private static boolean namespaceExists(final String namespace, final RemoteRepositoryManager repo) throws Exception{
		final GraphQueryResult res = repo.getRepositoryDescriptions();
		try{
			while(res.hasNext()){
				final Statement stmt = res.next();
				if (stmt.getPredicate().toString().equals(SD.KB_NAMESPACE.stringValue())) {
					if(namespace.equals(stmt.getObject().stringValue())){
						log.info(String.format("Namespace %s already exists", namespace));
						return true;
					}
				}
			}
		} finally {
			res.close();
		}
		return false;
	}

}
