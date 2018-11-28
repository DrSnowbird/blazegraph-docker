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
 * See <a href="http://wiki.blazegraph.com/wiki/index.php/Blueprints_API_embedded_mode">Blueprints API embedded mode</a>
 */

package sample.blueprints.embedded;

import java.io.File;
import java.io.InputStream;

import org.apache.log4j.Logger;

import com.bigdata.blueprints.BigdataGraph;
import com.bigdata.blueprints.BigdataGraphFactory;
import com.tinkerpop.blueprints.Edge;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.util.io.graphml.GraphMLReader;

public class SampleBlazegraphBlueprintsEmbedded {
	
	protected static final Logger log = Logger.getLogger(SampleBlazegraphBlueprintsEmbedded.class);
	private static final String journalFile = "/tmp/testJournal-" + System.currentTimeMillis()
			+ ".jnl";
	
	public static void main(String[] args) throws Exception {
		
			final File f = new File(journalFile);				
			
			//Make sure were starting with a clean file.
			f.delete();

			final BigdataGraph g = BigdataGraphFactory.create(journalFile);
			
			final InputStream is = SampleBlazegraphBlueprintsEmbedded.class
					.getClassLoader().getResourceAsStream("graph-example-1.xml");
			try {
				
				GraphMLReader.inputGraph(g, is);
				
			} finally {
				is.close();
			}
			
			try {
	
				for (final Vertex v : g.getVertices()) {
					log.info(v);
				}
				for (final Edge e : g.getEdges()) {
					log.info(e);
				}
				
			} finally  {
				
				g.shutdown();	
				
				f.delete();
				
			}
			
	}
	
}
